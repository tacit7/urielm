defmodule Urielm.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :name, :string
    field :avatar_url, :string
    field :email_verified, :boolean, default: false
    field :active, :boolean, default: true

    has_many :oauth_identities, Urielm.Accounts.OAuthIdentity
    has_many :saved_prompts, Urielm.Accounts.SavedPrompt
    has_many :comments, Urielm.Content.Comment
    has_many :likes, Urielm.Content.Like

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :avatar_url, :email_verified, :active])
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
    |> unique_constraint(:email)
  end
end
