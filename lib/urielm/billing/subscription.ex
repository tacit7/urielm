defmodule Urielm.Billing.Subscription do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "subscriptions" do
    belongs_to :user, Urielm.Accounts.User, type: :id

    field :status, :string, default: "active"
    field :current_period_end, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(subscription, attrs) do
    subscription
    |> cast(attrs, [:user_id, :status, :current_period_end])
    |> validate_required([:user_id, :status])
    |> validate_inclusion(:status, ["active", "canceled", "past_due"])
    |> unique_constraint(:user_id)
  end
end
