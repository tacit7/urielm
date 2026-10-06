defmodule Urielm.Chat do
  @moduledoc """
  The Chat context.
  """

  import Ecto.Query, warn: false
  alias Urielm.Accounts.User
  alias Urielm.Repo
  alias Urielm.Chat.{Room, RoomMembership, Message}

  # Rooms

  def list_rooms do
    Repo.all(Room)
  end

  def list_rooms_for_user(user_id) do
    Room
    |> join(:inner, [r], m in RoomMembership, on: m.room_id == r.id)
    |> where([_r, m], m.user_id == ^user_id)
    |> order_by([r], asc: r.name)
    |> Repo.all()
  end

  def get_room(id) do
    Repo.get(Room, id)
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

  def member?(user_id, room_id) do
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

  @doc """
  Removes membership and announces revocation after the deletion commits.

  Must be called outside an Ecto transaction so a later rollback cannot emit a
  revocation for membership that was retained.
  """
  def remove_member(user_id, room_id) do
    if Repo.in_transaction?() do
      raise ArgumentError, "remove_member/2 must be called outside a transaction"
    end

    with {:ok, user_id} <- valid_id(user_id),
         {:ok, room_id} <- valid_id(room_id) do
      result =
        Repo.delete_all(
          from(m in RoomMembership,
            where: m.user_id == ^user_id and m.room_id == ^room_id
          )
        )

      case result do
        {count, _} when count > 0 ->
          Phoenix.PubSub.broadcast(
            Urielm.PubSub,
            membership_topic(user_id, room_id),
            {:room_access_revoked, user_id, room_id}
          )

        _ ->
          :ok
      end

      result
    else
      {:error, :unauthorized} -> {0, nil}
    end
  end

  def membership_topic(user_id, room_id), do: "chat_membership:#{user_id}:#{room_id}"

  @doc "Checks membership against the current account state; silenced users may read."
  def authorize_access(user_id, room_id) do
    with {:ok, user_id} <- valid_id(user_id),
         {:ok, room_id} <- valid_id(room_id),
         %User{active: true} = user <- Repo.get(User, user_id),
         false <- User.suspended?(user),
         true <- member?(user_id, room_id) do
      {:ok, user}
    else
      _ -> {:error, :unauthorized}
    end
  end

  @doc "Checks current room membership and account restrictions before posting."
  def authorize_post(user_id, room_id) do
    with {:ok, user} <- authorize_access(user_id, room_id) do
      if User.silenced?(user), do: {:error, :silenced}, else: {:ok, user}
    end
  end

  defp valid_id(id) do
    case Ecto.Type.cast(:id, id) do
      {:ok, id} when is_integer(id) and id > 0 and id <= 9_223_372_036_854_775_807 ->
        {:ok, id}

      _ ->
        {:error, :unauthorized}
    end
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
    changeset = Message.changeset(%Message{}, Urielm.Params.normalize(attrs))

    if changeset.valid? do
      user_id = Ecto.Changeset.get_field(changeset, :user_id)
      room_id = Ecto.Changeset.get_field(changeset, :room_id)

      with {:ok, user_id} <- valid_id(user_id),
           {:ok, room_id} <- valid_id(room_id) do
        Repo.transact(fn ->
          # The membership lock serializes insertion with concurrent removal.
          membership =
            Repo.one(
              from(m in RoomMembership,
                where: m.user_id == ^user_id and m.room_id == ^room_id,
                lock: "FOR UPDATE"
              )
            )

          with %RoomMembership{} <- membership,
               {:ok, _user} <- authorize_post(user_id, room_id) do
            Repo.insert(changeset)
          else
            nil -> {:error, :unauthorized}
            {:error, reason} -> {:error, reason}
          end
        end)
      end
    else
      Repo.insert(changeset)
    end
  end

  def get_message!(id) do
    Repo.get!(Message, id)
  end

  def delete_message(%Message{} = message) do
    Repo.delete(message)
  end
end
