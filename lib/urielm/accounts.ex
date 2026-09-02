defmodule Urielm.Accounts do
  @moduledoc """
  The Accounts context handles user authentication and user-related operations.
  """

  import Ecto.Query, warn: false
  alias Urielm.Repo
  alias Urielm.Accounts.{User, OAuthIdentity, SavedPrompt, UserFollow}
  alias Urielm.Content.Prompt
  alias Urielm.Engagement

  ## User functions

  @doc """
  Gets a single user by ID.
  """
  def get_user(id), do: Repo.get(User, id)

  @doc """
  Paginates users with Flop. Supports search by username/email and filtering
  by status (active/suspended/silenced).

  Returns `{:ok, users, meta}` or `{:error, meta}`.

  ## Options
  - `:status` - "active" | "suspended" | "silenced"
  - `:search` - string to match against username or email (ilike)
  """
  def paginate_users(params \\ %{}, opts \\ []) do
    status = Keyword.get(opts, :status)
    search = Keyword.get(opts, :search)

    base =
      from(u in User)
      |> maybe_filter_user_status(status)
      |> maybe_search_users(search)

    Flop.validate_and_run(base, params, for: User, repo: Repo)
  end

  defp maybe_filter_user_status(query, nil), do: query

  defp maybe_filter_user_status(query, "suspended") do
    where(query, [u], not is_nil(u.suspended_at))
  end

  defp maybe_filter_user_status(query, "silenced") do
    where(query, [u], not is_nil(u.silenced_at))
  end

  defp maybe_filter_user_status(query, "active") do
    where(query, [u], is_nil(u.suspended_at) and is_nil(u.silenced_at))
  end

  defp maybe_search_users(query, nil), do: query
  defp maybe_search_users(query, ""), do: query

  defp maybe_search_users(query, search) do
    term = "%#{search}%"
    where(query, [u], ilike(u.username, ^term) or ilike(u.email, ^term))
  end

  @doc """
  Gets a user by email.
  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Finds or creates a user from OAuth authentication data.
  """
  def find_or_create_user(%Ueberauth.Auth{} = auth) do
    email = extract_email(auth)
    provider = to_string(auth.provider)
    provider_uid = auth.uid

    case get_oauth_identity(provider, provider_uid) do
      nil ->
        create_user_from_oauth(auth, email, provider, provider_uid)

      identity ->
        {:ok, identity |> Repo.preload(:user) |> Map.get(:user)}
    end
  end

  defp extract_email(%Ueberauth.Auth{info: %{email: email}}) when is_binary(email), do: email
  defp extract_email(_), do: nil

  defp get_oauth_identity(provider, provider_uid) do
    Repo.get_by(OAuthIdentity, provider: provider, provider_uid: provider_uid)
  end

  defp create_user_from_oauth(auth, email, provider, provider_uid) do
    Repo.transaction(fn ->
      user_params = %{
        email: email || "#{provider}_#{provider_uid}@temporary.local",
        name: auth.info.name,
        avatar_url: auth.info.image,
        email_verified: email != nil
      }

      {:ok, user} =
        %User{}
        |> User.changeset(user_params)
        |> Repo.insert()

      identity_params = %{
        user_id: user.id,
        provider: provider,
        provider_uid: provider_uid,
        raw_info: Map.from_struct(auth.info)
      }

      %OAuthIdentity{}
      |> OAuthIdentity.changeset(identity_params)
      |> Repo.insert!()

      user
    end)
  end

  ## Email/Password Authentication

  @doc """
  Registers a new user with email and password.
  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Registers a new user with email and password only (no username yet).
  Email verification required before posting/commenting.
  """
  def register_user_email_only(attrs) do
    %User{}
    |> User.email_only_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Authenticates a user with email and password.
  Returns {:ok, user} if credentials are valid, {:error, :invalid_credentials} otherwise.
  """
  def authenticate_user(email, password) when is_binary(email) and is_binary(password) do
    user = get_user_by_email(email)

    cond do
      user && User.valid_password?(user, password) ->
        {:ok, user}

      user ->
        {:error, :invalid_credentials}

      true ->
        # Run a dummy password check to prevent timing attacks
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}
    end
  end

  @doc """
  Returns a changeset for tracking user profile changes.
  """
  def change_user_profile(%User{} = user, attrs \\ %{}) do
    User.profile_changeset(user, attrs)
  end

  @doc """
  Returns form data for a user's forum capability badge preferences.
  """
  def change_user_capability_badges(%User{} = user) do
    settings = User.capability_badge_settings(user)

    %{
      "agent_badge_enabled" => settings["agent_badge_enabled"],
      "capability_chips_enabled" => settings["capability_chips_enabled"],
      "agent_name" => settings["agent_name"],
      "model_name" => settings["model_name"],
      "provider" => settings["provider"],
      "skills_text" => capability_names_text(settings["visible_capabilities"], "skill"),
      "tools_text" => capability_names_text(settings["visible_capabilities"], "tool")
    }
  end

  defp capability_names_text(capabilities, kind) when is_list(capabilities) do
    capabilities
    |> Enum.filter(&(Map.get(&1, "kind") == kind))
    |> Enum.map(&Map.get(&1, "name", ""))
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n")
  end

  defp capability_names_text(_capabilities, _kind), do: ""

  @doc """
  Updates a user's profile information.

  Casts every profile-related field including `:email`. Reserved for internal
  and OAuth callers that legitimately set the email of record. Do NOT feed raw
  params from the profile form here; use `update_user_profile/2` for that.
  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a user's self-service profile fields (display name, bio, location,
  website, avatar URL).

  Cannot change email, email verification, account state, or username. This is
  the only path the profile form is allowed to reach.
  """
  def update_user_profile(%User{} = user, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a user's forum capability badge preferences.
  """
  def update_user_capability_badges(%User{} = user, attrs) do
    user
    |> User.capability_badge_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a user's password. Only touches the password hash.
  """
  def update_user_password(%User{} = user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns whether `viewer` may view `profile_user`'s profile details.

  Private profiles are visible only to their owner and moderators. Follow
  requests/approval do not exist yet, so following alone does not grant access.
  """
  def can_view_profile?(%User{id: user_id}, %User{id: user_id}), do: true

  def can_view_profile?(%User{is_admin: true}, %User{}), do: true
  def can_view_profile?(%User{is_moderator: true}, %User{}), do: true

  def can_view_profile?(_viewer, %User{private_profile: true}), do: false
  def can_view_profile?(_viewer, %User{}), do: true

  @doc """
  Deletes a user account and all associated data.
  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  ## Saved Prompts

  @doc """
  Saves a prompt for a user.
  """
  def save_prompt(%User{id: user_id}, prompt_id) do
    %SavedPrompt{}
    |> SavedPrompt.changeset(%{user_id: user_id, prompt_id: prompt_id})
    |> Repo.insert()
    |> case do
      {:ok, saved} ->
        increment_prompt_counter(prompt_id, :saves_count)
        {:ok, saved}

      error ->
        error
    end
  end

  @doc """
  Unsaves a prompt for a user.
  """
  def unsave_prompt(%User{id: user_id}, prompt_id) do
    case Repo.get_by(SavedPrompt, user_id: user_id, prompt_id: prompt_id) do
      nil ->
        {:error, :not_found}

      saved_prompt ->
        Repo.delete(saved_prompt)
        decrement_prompt_counter(prompt_id, :saves_count)
        {:ok, saved_prompt}
    end
  end

  @doc """
  Checks if a prompt is saved by a user.
  """
  def prompt_saved?(%User{id: user_id}, prompt_id) do
    Urielm.Content.user_saved_prompt?(user_id, prompt_id)
  end

  def prompt_saved?(nil, _prompt_id), do: false

  @doc """
  Gets all saved prompts for a user with prompt details.
  """
  def list_saved_prompts(%User{id: user_id}) do
    from(s in SavedPrompt,
      where: s.user_id == ^user_id,
      join: p in assoc(s, :prompt),
      preload: [prompt: p],
      order_by: [desc: s.inserted_at]
    )
    |> Repo.all()
    |> Enum.map(& &1.prompt)
  end

  ## Likes (using unified Engagement.Vote system)

  @doc """
  Likes a prompt for a user. Uses +1 vote value.
  """
  def like_prompt(%User{id: user_id}, prompt_id) do
    target_id = to_string(prompt_id)

    case Engagement.cast_vote(user_id, "prompt", target_id, 1) do
      {:ok, vote} ->
        increment_prompt_counter(prompt_id, :likes_count)
        {:ok, vote}

      error ->
        error
    end
  end

  @doc """
  Unlikes a prompt for a user.
  """
  def unlike_prompt(%User{id: user_id}, prompt_id) do
    target_id = to_string(prompt_id)

    case Engagement.unvote(user_id, "prompt", target_id) do
      {:ok, nil} ->
        {:error, :not_found}

      {:ok, _vote} ->
        decrement_prompt_counter(prompt_id, :likes_count)
        {:ok, :unliked}

      error ->
        error
    end
  end

  @doc """
  Checks if a prompt is liked by a user.
  """
  def prompt_liked?(%User{id: user_id}, prompt_id) do
    Urielm.Content.user_liked_prompt?(user_id, prompt_id)
  end

  def prompt_liked?(nil, _prompt_id), do: false

  ## User Profiles

  def get_user_by_username(username) when is_binary(username) do
    from(u in User, where: fragment("LOWER(?)", u.username) == fragment("LOWER(?)", ^username))
    |> Repo.one()
  end

  def get_user_stats(user_id) do
    from_count =
      from(t in Urielm.Forum.Thread, where: t.author_id == ^user_id and t.is_removed == false)
      |> Repo.aggregate(:count)

    comment_count =
      from(c in Urielm.Forum.Comment, where: c.author_id == ^user_id and c.is_removed == false)
      |> Repo.aggregate(:count)

    follower_count = count_followers(user_id)
    following_count = count_following(user_id)

    %{
      thread_count: from_count,
      comment_count: comment_count,
      follower_count: follower_count,
      following_count: following_count
    }
  end

  ## User Following

  def follow_user(follower_id, following_id) do
    %UserFollow{}
    |> UserFollow.changeset(%{follower_id: follower_id, following_id: following_id})
    |> Repo.insert()
  end

  def unfollow_user(follower_id, following_id) do
    case Repo.get_by(UserFollow, follower_id: follower_id, following_id: following_id) do
      nil -> {:error, :not_found}
      follow -> Repo.delete(follow)
    end
  end

  def following?(follower_id, following_id) do
    Repo.exists?(
      from(uf in UserFollow,
        where: uf.follower_id == ^follower_id and uf.following_id == ^following_id
      )
    )
  end

  def toggle_follow(follower_id, following_id) do
    if following?(follower_id, following_id) do
      unfollow_user(follower_id, following_id)
    else
      follow_user(follower_id, following_id)
    end
  end

  def count_followers(user_id) do
    from(uf in UserFollow, where: uf.following_id == ^user_id)
    |> Repo.aggregate(:count)
  end

  def count_following(user_id) do
    from(uf in UserFollow, where: uf.follower_id == ^user_id)
    |> Repo.aggregate(:count)
  end

  ## Moderator Management (Admin only)

  def update_trust_level(%User{} = user, trust_level, %{is_admin: true} = _admin)
      when trust_level in 0..4 do
    user
    |> Ecto.Changeset.change(trust_level: trust_level)
    |> Repo.update()
  end

  def update_trust_level(_user, _level, _non_admin), do: {:error, :unauthorized}

  def grant_moderator(%User{} = user, %{is_admin: true} = _admin) do
    user
    |> Ecto.Changeset.change(is_moderator: true)
    |> Repo.update()
  end

  def grant_moderator(_user, _non_admin), do: {:error, :unauthorized}

  def revoke_moderator(%User{} = user, %{is_admin: true} = _admin) do
    user
    |> Ecto.Changeset.change(is_moderator: false)
    |> Repo.update()
  end

  def revoke_moderator(_user, _non_admin), do: {:error, :unauthorized}

  ## User Suspension (Admin/Mod only)

  @doc """
  Suspends a user. Suspended users cannot login.

  Options:
  - :reason - Required reason for suspension
  - :until - DateTime when suspension expires (nil = permanent)
  """
  def suspend_user(%User{} = user, %{is_admin: true} = _admin, opts) do
    do_suspend_user(user, opts)
  end

  def suspend_user(%User{} = user, %{is_moderator: true} = _moderator, opts) do
    do_suspend_user(user, opts)
  end

  def suspend_user(_user, _non_mod, _opts), do: {:error, :unauthorized}

  defp do_suspend_user(user, opts) do
    reason = Keyword.fetch!(opts, :reason)
    until = Keyword.get(opts, :until)

    user
    |> User.suspension_changeset(%{
      suspended_at: DateTime.utc_now(),
      suspended_until: until,
      suspended_reason: reason
    })
    |> Repo.update()
  end

  @doc """
  Removes suspension from a user.
  """
  def unsuspend_user(%User{} = user, %{is_admin: true} = _admin) do
    do_unsuspend_user(user)
  end

  def unsuspend_user(%User{} = user, %{is_moderator: true} = _moderator) do
    do_unsuspend_user(user)
  end

  def unsuspend_user(_user, _non_mod), do: {:error, :unauthorized}

  defp do_unsuspend_user(user) do
    user
    |> User.suspension_changeset(%{
      suspended_at: nil,
      suspended_until: nil,
      suspended_reason: nil
    })
    |> Repo.update()
  end

  ## User Silencing (Admin/Mod only)

  @doc """
  Silences a user. Silenced users can read but cannot post/vote/interact.

  Options:
  - :reason - Required reason for silencing
  - :until - DateTime when silencing expires (nil = permanent)
  """
  def silence_user(%User{} = user, %{is_admin: true} = _admin, opts) do
    do_silence_user(user, opts)
  end

  def silence_user(%User{} = user, %{is_moderator: true} = _moderator, opts) do
    do_silence_user(user, opts)
  end

  def silence_user(_user, _non_mod, _opts), do: {:error, :unauthorized}

  defp do_silence_user(user, opts) do
    reason = Keyword.fetch!(opts, :reason)
    until = Keyword.get(opts, :until)

    user
    |> User.silencing_changeset(%{
      silenced_at: DateTime.utc_now(),
      silenced_until: until,
      silenced_reason: reason
    })
    |> Repo.update()
  end

  @doc """
  Removes silencing from a user.
  """
  def unsilence_user(%User{} = user, %{is_admin: true} = _admin) do
    do_unsilence_user(user)
  end

  def unsilence_user(%User{} = user, %{is_moderator: true} = _moderator) do
    do_unsilence_user(user)
  end

  def unsilence_user(_user, _non_mod), do: {:error, :unauthorized}

  defp do_unsilence_user(user) do
    user
    |> User.silencing_changeset(%{
      silenced_at: nil,
      silenced_until: nil,
      silenced_reason: nil
    })
    |> Repo.update()
  end

  ## Counter helpers

  defp increment_prompt_counter(prompt_id, counter_field) do
    from(p in Prompt, where: p.id == ^prompt_id)
    |> Repo.update_all(inc: [{counter_field, 1}])
  end

  defp decrement_prompt_counter(prompt_id, counter_field) do
    from(p in Prompt, where: p.id == ^prompt_id)
    |> Repo.update_all(inc: [{counter_field, -1}])
  end
end
