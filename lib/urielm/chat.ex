defmodule Urielm.Chat do
  @moduledoc """
  The Chat context.
  """

  import Ecto.Query, warn: false
  alias Urielm.Repo
  alias Urielm.Chat.{Room, RoomMembership, Message}

  # Rooms

  def list_rooms do
    Repo.all(Room)
  end

  def get_room!(id) do
    Repo.get!(Room, id)
  end

  def get_room_by_name(name) do
    Repo.get_by(Room, name: name)
  end

  def create_room(attrs \\ %{}) do
    %Room{}
    |> Room.changeset(attrs)
    |> Repo.insert()
  end

  def update_room(%Room{} = room, attrs) do
    attrs = Urielm.Params.normalize(attrs)
    room
    |> Room.changeset(attrs)
    |> Repo.update()
  end

  def delete_room(%Room{} = room) do
    Repo.delete(room)
  end

  # Room Memberships

  def list_room_members(room_id) do
    RoomMembership
    |> where(room_id: ^room_id)
    |> preload(:user)
    |> Repo.all()
  end

  def is_member?(user_id, room_id) do
    Repo.exists?(
      from(m in RoomMembership,
        where: m.user_id == ^user_id and m.room_id == ^room_id
      )
    )
  end

  def add_member(user_id, room_id) do
    %RoomMembership{}
    |> RoomMembership.changeset(%{user_id: user_id, room_id: room_id})
    |> Repo.insert(on_conflict: :nothing)
  end

  def remove_member(user_id, room_id) do
    Repo.delete_all(
      from(m in RoomMembership,
        where: m.user_id == ^user_id and m.room_id == ^room_id
      )
    )
  end

  # Messages

  def list_room_messages(room_id, limit \\ 50) do
    Message
    |> where(room_id: ^room_id)
    |> preload(:user)
    |> order_by(asc: :inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  def get_message!(id) do
    Repo.get!(Message, id)
  end

  def delete_message(%Message{} = message) do
    Repo.delete(message)
  end
end
