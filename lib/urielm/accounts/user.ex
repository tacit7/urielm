defmodule Urielm.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Flop.Schema,
           filterable: [:username, :email, :trust_level],
           sortable: [:username, :email, :trust_level, :inserted_at, :is_moderator, :is_admin]}

  schema "users" do
    field(:email, :string)
    field(:name, :string)
    field(:username, :string)
    field(:display_name, :string)
    field(:avatar_url, :string)
    field(:bio, :string)
    field(:location, :string)
    field(:website, :string)
    field(:private_profile, :boolean, default: false)
    field(:email_verified, :boolean, default: false)
    field(:active, :boolean, default: true)
    field(:is_admin, :boolean, default: false)
    field(:is_moderator, :boolean, default: false)
    field(:password_hash, :string)
    field(:password, :string, virtual: true)
    field(:trust_level, :integer, default: 0)
    field(:trust_level_locked, :boolean, default: false)

    # Suspension (cannot login)
    field(:suspended_at, :utc_datetime)
    field(:suspended_until, :utc_datetime)
    field(:suspended_reason, :string)

    # Silencing (can read, cannot post)
    field(:silenced_at, :utc_datetime)
    field(:silenced_until, :utc_datetime)
    field(:silenced_reason, :string)

    has_many(:oauth_identities, Urielm.Accounts.OAuthIdentity)
    has_many(:saved_prompts, Urielm.Accounts.SavedPrompt)
    has_many(:comments, Urielm.Content.Comment)
    has_many(:room_memberships, Urielm.Chat.RoomMembership)
    has_many(:rooms, through: [:room_memberships, :room])
    has_many(:messages, Urielm.Chat.Message)
    has_many(:forum_threads, Urielm.Forum.Thread, foreign_key: :author_id)
    has_many(:forum_comments, Urielm.Forum.Comment, foreign_key: :author_id)
    has_many(:votes, Urielm.Engagement.Vote, foreign_key: :user_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :email,
      :name,
      :username,
      :display_name,
      :avatar_url,
      :bio,
      :location,
      :website,
      :private_profile,
      :email_verified,
      :active
    ])
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
    |> validate_length(:bio, max: 1000)
    |> validate_length(:location, max: 100)
    |> validate_length(:website, max: 200)
    |> validate_handle()
    |> validate_display_name()
    |> unique_constraint(:email)
    |> unique_constraint(:username)
  end

  @doc """
  Changeset for self-service profile edits from the profile form.

  Casts only the fields a user may freely change about their own public
  profile. It deliberately does NOT cast `:email`, `:email_verified`,
  `:active` or `:username`, so the profile form cannot be used to take over
  another account's email (the key OAuth identities link against) or to flip
  account state. Email changes and moderation flags go through dedicated,
  authorized changesets.
  """
  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [:display_name, :bio, :location, :website, :avatar_url, :private_profile])
    |> validate_length(:bio, max: 1000)
    |> validate_length(:location, max: 100)
    |> validate_length(:website, max: 200)
    |> validate_display_name()
  end

  defp validate_display_name(changeset) do
    changeset
    |> validate_length(:display_name, min: 2, max: 50)
  end

  defp validate_handle(changeset) do
    changeset
    |> validate_format(:username, ~r/^(?=.{3,20}$)[a-z0-9]+([_-][a-z0-9]+)*$/,
      message:
        "must be 3-20 lowercase letters, numbers, dashes or underscores; no leading/trailing dashes"
    )
  end

  @doc """
  Changeset for user registration with email and password.
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :username, :display_name, :password])
    |> validate_required([:email, :password, :username, :display_name])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
    |> validate_length(:password, min: 8, message: "must be at least 8 characters")
    |> validate_handle()
    |> unique_constraint(:email)
    |> unique_constraint(:username)
    |> put_password_hash(verify_email: true)
  end

  @doc """
  Changeset for email-only registration (username collected later).
  Email verification required before posting/commenting.
  """
  def email_only_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
    |> validate_length(:password, min: 8, message: "must be at least 8 characters")
    |> unique_constraint(:email)
    |> put_password_hash(verify_email: false)
  end

  defp put_password_hash(
         %Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset,
         opts
       ) do
    verify_email = Keyword.get(opts, :verify_email, false)

    changeset
    |> put_change(:password_hash, Bcrypt.hash_pwd_salt(password))
    |> put_change(:email_verified, verify_email)
  end

  defp put_password_hash(changeset, _opts), do: changeset

  @doc """
  Changeset for changing the password on an existing account.

  Sets only `:password_hash`. Unlike `registration_changeset/2` it never
  touches `:email_verified`, so changing a password cannot silently mark an
  unverified email as verified.
  """
  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_length(:password, min: 8, message: "must be at least 8 characters")
    |> put_password_change_hash()
  end

  defp put_password_change_hash(
         %Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset
       ) do
    put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(password))
  end

  defp put_password_change_hash(changeset), do: changeset

  @doc """
  Verify a plain text password against the stored hash.
  """
  def valid_password?(%__MODULE__{password_hash: password_hash}, password)
      when is_binary(password_hash) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, password_hash)
  end

  def valid_password?(_, _), do: false

  @doc """
  Check if user is currently suspended.
  Returns true if suspended_at is set and suspension hasn't expired.
  """
  def suspended?(%__MODULE__{suspended_at: nil}), do: false

  def suspended?(%__MODULE__{suspended_until: nil}), do: true

  def suspended?(%__MODULE__{suspended_until: until}) do
    DateTime.compare(DateTime.utc_now(), until) == :lt
  end

  @doc """
  Check if user is currently silenced.
  Returns true if silenced_at is set and silencing hasn't expired.
  """
  def silenced?(%__MODULE__{silenced_at: nil}), do: false

  def silenced?(%__MODULE__{silenced_until: nil}), do: true

  def silenced?(%__MODULE__{silenced_until: until}) do
    DateTime.compare(DateTime.utc_now(), until) == :lt
  end

  @doc """
  Changeset for suspending a user.
  """
  def suspension_changeset(user, attrs) do
    user
    |> cast(attrs, [:suspended_at, :suspended_until, :suspended_reason])
  end

  @doc """
  Changeset for silencing a user.
  """
  def silencing_changeset(user, attrs) do
    user
    |> cast(attrs, [:silenced_at, :silenced_until, :silenced_reason])
  end
end
