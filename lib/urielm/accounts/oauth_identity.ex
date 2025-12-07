defmodule Urielm.Accounts.OAuthIdentity do
  use Ecto.Schema
  import Ecto.Changeset

  schema "oauth_identities" do
    field(:provider, :string)
    field(:provider_uid, :string)
    field(:provider_token, :string)
    field(:raw_info, :map)

    belongs_to(:user, Urielm.Accounts.User)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(oauth_identity, attrs) do
    oauth_identity
    |> cast(attrs, [:provider, :provider_uid, :provider_token, :raw_info, :user_id])
    |> validate_required([:provider, :provider_uid, :user_id])
    |> validate_inclusion(:provider, ["google", "twitter", "facebook"])
    |> unique_constraint([:provider, :provider_uid])
  end
end
