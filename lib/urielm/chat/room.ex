defmodule Urielm.Chat.Room do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rooms" do
    field :name, :string
    field :description, :string
    field :created_by_id, :id

    has_many :memberships, Urielm.Chat.RoomMembership
    has_many :users, through: [:memberships, :user]
    has_many :messages, Urielm.Chat.Message

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, [:name, :description, :created_by_id])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
