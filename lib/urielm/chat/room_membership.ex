defmodule Urielm.Chat.RoomMembership do
  use Ecto.Schema
  import Ecto.Changeset

  schema "room_memberships" do
    belongs_to :user, Urielm.Accounts.User
    belongs_to :room, Urielm.Chat.Room

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:user_id, :room_id])
    |> validate_required([:user_id, :room_id])
    |> unique_constraint([:user_id, :room_id])
  end
end
