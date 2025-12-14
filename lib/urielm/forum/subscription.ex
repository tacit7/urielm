defmodule Urielm.Forum.Subscription do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "forum_subscriptions" do
    belongs_to(:user, Urielm.Accounts.User, type: :id)
    belongs_to(:thread, Urielm.Forum.Thread)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(subscription, attrs) do
    subscription
    |> cast(attrs, [:user_id, :thread_id])
    |> validate_required([:user_id, :thread_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:thread_id)
    |> unique_constraint([:user_id, :thread_id])
  end
end
