defmodule Urielm.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:email, :string)
    field(:name, :string)
    field(:username, :string)
    field(:avatar_url, :string)
    field(:email_verified, :boolean, default: false)
    field(:active, :boolean, default: true)
    field(:is_admin, :boolean, default: false)
    field(:password_hash, :string)
    field(:password, :string, virtual: true)

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
    |> cast(attrs, [:email, :name, :username, :avatar_url, :email_verified, :active])
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
    |> validate_username()
    |> unique_constraint(:email)
    |> unique_constraint(:username)
  end

  defp validate_username(changeset) do
    changeset
    |> validate_format(:username, ~r/^[a-zA-Z0-9_]+$/,
      message: "can only contain letters, numbers, and underscores"
    )
    |> validate_length(:username, min: 3, max: 20)
  end

  @doc """
  Changeset for user registration with email and password.
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :username, :password])
    |> validate_required([:email, :password])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
    |> validate_length(:password, min: 8, message: "must be at least 8 characters")
    |> validate_username()
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
