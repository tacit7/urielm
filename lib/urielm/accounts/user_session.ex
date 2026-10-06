defmodule Urielm.Accounts.UserSession do
  use Ecto.Schema

  schema "user_sessions" do
    belongs_to(:user, Urielm.Accounts.User)
    field(:token_hash, :binary)
    field(:credential_hash, :binary)
    field(:context, :string)
    field(:expires_at, :utc_datetime)
    timestamps(type: :utc_datetime, updated_at: false)
  end
end
