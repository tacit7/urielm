defmodule Urielm.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:email, :string)
    field(:name, :string)
    field(:username, :string)
    field(:display_name, :string)
    field(:avatar_url, :string)
    field(:email_verified, :boolean, default: false)
    field(:active, :boolean, default: true)
    field(:is_admin, :boolean, default: false)
    field(:password_hash, :string)
    field(:password, :string, virtual: true)
    field(:trust_level, :integer, default: 0)
    field(:trust_level_locked, :boolean, default: false)

    has_many(:oauth_identities, Urielm.Accounts.OAuthIdentity)
    has_many(:saved_prompts, Urielm.Accounts.SavedPrompt)
    has_many(:comments, Urielm.Content.Comment)
    has_many(:likes, Urielm.Content.Like)
    has_many(:room_memberships, Urielm.Chat.RoomMembership)
    has_many(:rooms, through: [:room_memberships, :room])
    has_many(:messages, Urielm.Chat.Message)
    has_many(:forum_threads, Urielm.Forum.Thread, foreign_key: :author_id)
    has_many(:forum_comments, Urielm.Forum.Comment, foreign_key: :author_id)
    has_many(:forum_votes, Urielm.Forum.Vote, foreign_key: :user_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :username, :display_name, :avatar_url, :email_verified, :active])
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
    |> validate_handle()
    |> unique_constraint(:email)
    |> unique_constraint(:username)
  end

  defp validate_handle(changeset) do
    changeset
    |> validate_format(:username, ~r/^(?=.{3,20}$)[a-z0-9]+([_-][a-z0-9]+)*$/,
      message: "must be 3-20 lowercase letters, numbers, dashes or underscores; no leading/trailing dashes"
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
    |> put_password_hash()
  end

  defp put_password_hash(
         %Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset
       ) do
    changeset
    |> put_change(:password_hash, Bcrypt.hash_pwd_salt(password))
    # Auto-verify for email/password signups
    |> put_change(:email_verified, true)
  end

  defp put_password_hash(changeset), do: changeset

  @doc """
  Verify a plain text password against the stored hash.
  """
  def valid_password?(%__MODULE__{password_hash: password_hash}, password)
      when is_binary(password_hash) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, password_hash)
  end

  def valid_password?(_, _), do: false
end
