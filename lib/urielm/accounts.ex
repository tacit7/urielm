defmodule Urielm.Accounts do
  @moduledoc """
  The Accounts context handles user authentication and user-related operations.
  """

  import Ecto.Query, warn: false
  alias Urielm.Repo
  alias Urielm.Accounts.{User, OAuthIdentity, SavedPrompt, UserFollow}
  alias Urielm.Content.{Like, Prompt}

  ## User functions

  @doc """
  Gets a single user by ID.
  """
  def get_user(id), do: Repo.get(User, id)

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
        provider_token: auth.credentials.token,
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
  Updates a user's profile information.
  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a user's password.
  """
  def update_user_password(%User{} = user, attrs) do
    user
    |> User.registration_changeset(attrs)
    |> Repo.update()
  end

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
  def is_prompt_saved?(%User{id: user_id}, prompt_id) do
    Urielm.Content.user_saved_prompt?(user_id, prompt_id)
  end

  def is_prompt_saved?(nil, _prompt_id), do: false

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

  ## Likes

  @doc """
  Likes a prompt for a user.
  """
  def like_prompt(%User{id: user_id}, prompt_id) do
    %Like{}
    |> Like.changeset(%{user_id: user_id, prompt_id: prompt_id})
    |> Repo.insert()
    |> case do
      {:ok, like} ->
        increment_prompt_counter(prompt_id, :likes_count)
        {:ok, like}

      error ->
        error
    end
  end

  @doc """
  Unlikes a prompt for a user.
  """
  def unlike_prompt(%User{id: user_id}, prompt_id) do
    case Repo.get_by(Like, user_id: user_id, prompt_id: prompt_id) do
      nil ->
        {:error, :not_found}

      like ->
        Repo.delete(like)
        decrement_prompt_counter(prompt_id, :likes_count)
        {:ok, like}
    end
  end

  @doc """
  Checks if a prompt is liked by a user.
  """
  def is_prompt_liked?(%User{id: user_id}, prompt_id) do
    Urielm.Content.user_liked_prompt?(user_id, prompt_id)
  end

  def is_prompt_liked?(nil, _prompt_id), do: false

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

  def is_following?(follower_id, following_id) do
    Repo.exists?(
      from(uf in UserFollow,
        where: uf.follower_id == ^follower_id and uf.following_id == ^following_id
      )
    )
  end

  def toggle_follow(follower_id, following_id) do
    if is_following?(follower_id, following_id) do
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
