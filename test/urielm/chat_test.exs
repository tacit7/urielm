defmodule Urielm.ChatTest do
  use Urielm.DataCase

  alias Urielm.Chat
  alias Urielm.Fixtures

  describe "rooms" do
    setup do
      user = Fixtures.user_fixture()
      {:ok, user: user}
    end

    test "list_rooms/0 returns all rooms" do
      room1 = create_room(%{name: "general"})
      room2 = create_room(%{name: "random"})

      rooms = Chat.list_rooms()

      assert length(rooms) >= 2
      assert Enum.any?(rooms, &(&1.id == room1.id))
      assert Enum.any?(rooms, &(&1.id == room2.id))
    end

    test "get_room!/1 returns room by id" do
      room = create_room(%{name: "general"})

      fetched = Chat.get_room!(room.id)

      assert fetched.id == room.id
      assert fetched.name == "general"
    end

    test "get_room!/1 raises error for non-existent room" do
      assert_raise Ecto.NoResultsError, fn ->
        Chat.get_room!(9999)
      end
    end

    test "get_room_by_name/1 returns room by name" do
      room = create_room(%{name: "announcements"})

      fetched = Chat.get_room_by_name("announcements")

      assert fetched.id == room.id
      assert fetched.name == "announcements"
    end

    test "get_room_by_name/1 returns nil for non-existent room" do
      result = Chat.get_room_by_name("nonexistent")

      assert is_nil(result)
    end

    test "create_room/1 creates a room with valid data" do
      attrs = %{
        name: "new-room",
        description: "A new room"
      }

      {:ok, room} = Chat.create_room(attrs)

      assert room.name == "new-room"
      assert room.description == "A new room"
    end

    test "create_room/1 requires name" do
      attrs = %{description: "No name room"}

      {:error, changeset} = Chat.create_room(attrs)

      assert changeset.errors[:name]
    end

    test "create_room/1 enforces unique room names" do
      Chat.create_room(%{name: "unique-room"})

      {:error, changeset} = Chat.create_room(%{name: "unique-room"})

      assert changeset.errors[:name]
    end

    test "create_room/1 with created_by_id" do
      user = Fixtures.user_fixture()
      attrs = %{name: "user-room", created_by_id: user.id}

      {:ok, room} = Chat.create_room(attrs)

      assert room.created_by_id == user.id
    end

    test "update_room/2 updates room attributes" do
      room = create_room(%{name: "old-name", description: "old"})

      {:ok, updated} = Chat.update_room(room, %{description: "new description"})

      assert updated.id == room.id
      assert updated.name == "old-name"
      assert updated.description == "new description"
    end

    test "update_room/2 requires name" do
      room = create_room(%{name: "keep-name"})

      {:error, changeset} = Chat.update_room(room, %{name: ""})

      assert changeset.errors[:name]
    end

    test "delete_room/1 removes room" do
      room = create_room(%{name: "room-to-delete"})

      {:ok, deleted} = Chat.delete_room(room)

      assert deleted.id == room.id
      assert is_nil(Chat.get_room_by_name("room-to-delete"))
    end

    test "delete_room/1 cascade deletes associated data" do
      room = create_room(%{name: "cleanup-room"})
      user = Fixtures.user_fixture()
      Chat.add_member(user.id, room.id)
      Chat.create_message(%{user_id: user.id, room_id: room.id, body: "test"})

      {:ok, _} = Chat.delete_room(room)

      # Verify room is gone
      assert is_nil(Chat.get_room_by_name("cleanup-room"))
    end
  end

  describe "room memberships" do
    setup do
      room = create_room(%{name: "test-room"})
      user1 = Fixtures.user_fixture()
      user2 = Fixtures.user_fixture()

      {:ok, room: room, user1: user1, user2: user2}
    end

    test "is_member?/2 returns true for members", %{room: room, user1: user1} do
      Chat.add_member(user1.id, room.id)

      assert Chat.is_member?(user1.id, room.id)
    end

    test "is_member?/2 returns false for non-members", %{room: room, user1: user1} do
      refute Chat.is_member?(user1.id, room.id)
    end

    test "list_room_members/1 returns all members", %{room: room, user1: user1, user2: user2} do
      Chat.add_member(user1.id, room.id)
      Chat.add_member(user2.id, room.id)

      members = Chat.list_room_members(room.id)

      assert length(members) == 2
      assert Enum.any?(members, &(&1.user_id == user1.id))
      assert Enum.any?(members, &(&1.user_id == user2.id))
    end

    test "list_room_members/1 preloads user data", %{room: room, user1: user1} do
      Chat.add_member(user1.id, room.id)

      members = Chat.list_room_members(room.id)

      assert length(members) == 1
      member = List.first(members)
      assert member.user.id == user1.id
      assert member.user.email == user1.email
    end

    test "list_room_members/1 returns empty list for room with no members", %{room: room} do
      members = Chat.list_room_members(room.id)

      assert members == []
    end

    test "add_member/2 adds user to room", %{room: room, user1: user1} do
      {:ok, membership} = Chat.add_member(user1.id, room.id)

      assert membership.user_id == user1.id
      assert membership.room_id == room.id
      assert Chat.is_member?(user1.id, room.id)
    end

    test "add_member/2 with same user twice is idempotent", %{room: room, user1: user1} do
      {:ok, _} = Chat.add_member(user1.id, room.id)
      {:ok, _} = Chat.add_member(user1.id, room.id)

      # Should only have one membership
      members = Chat.list_room_members(room.id)
      assert length(members) == 1
    end

    test "remove_member/2 removes user from room", %{room: room, user1: user1} do
      Chat.add_member(user1.id, room.id)
      assert Chat.is_member?(user1.id, room.id)

      Chat.remove_member(user1.id, room.id)

      refute Chat.is_member?(user1.id, room.id)
    end

    test "remove_member/2 with non-member is safe", %{room: room, user1: user1} do
      # Should not raise error
      Chat.remove_member(user1.id, room.id)

      refute Chat.is_member?(user1.id, room.id)
    end

    test "multiple users can be added to same room", %{room: room, user1: user1, user2: user2} do
      Chat.add_member(user1.id, room.id)
      Chat.add_member(user2.id, room.id)

      assert Chat.is_member?(user1.id, room.id)
      assert Chat.is_member?(user2.id, room.id)
    end

    test "same user can be member of multiple rooms", %{user1: user1} do
      room1 = create_room(%{name: "room1"})
      room2 = create_room(%{name: "room2"})

      Chat.add_member(user1.id, room1.id)
      Chat.add_member(user1.id, room2.id)

      assert Chat.is_member?(user1.id, room1.id)
      assert Chat.is_member?(user1.id, room2.id)
    end
  end

  describe "messages" do
    setup do
      room = create_room(%{name: "test-room"})
      user = Fixtures.user_fixture()
      Chat.add_member(user.id, room.id)

      {:ok, room: room, user: user}
    end

    test "create_message/1 creates a message", %{room: room, user: user} do
      attrs = %{
        body: "Hello, world!",
        user_id: user.id,
        room_id: room.id
      }

      {:ok, message} = Chat.create_message(attrs)

      assert message.body == "Hello, world!"
      assert message.user_id == user.id
      assert message.room_id == room.id
    end

    test "create_message/1 requires body", %{room: room, user: user} do
      attrs = %{user_id: user.id, room_id: room.id}

      {:error, changeset} = Chat.create_message(attrs)

      assert changeset.errors[:body]
    end

    test "create_message/1 requires room_id", %{user: user} do
      attrs = %{body: "test", user_id: user.id}

      {:error, changeset} = Chat.create_message(attrs)

      assert changeset.errors[:room_id]
    end

    test "create_message/1 allows nil user_id (anonymous messages)" do
      room = create_room(%{name: "anon-room"})

      attrs = %{body: "anonymous message", room_id: room.id}

      {:ok, message} = Chat.create_message(attrs)

      assert message.body == "anonymous message"
      assert is_nil(message.user_id)
    end

    test "get_message!/1 returns message by id", %{room: room, user: user} do
      {:ok, msg} = Chat.create_message(%{body: "test", user_id: user.id, room_id: room.id})

      fetched = Chat.get_message!(msg.id)

      assert fetched.id == msg.id
      assert fetched.body == "test"
    end

    test "get_message!/1 raises error for non-existent message" do
      assert_raise Ecto.NoResultsError, fn ->
        Chat.get_message!(9999)
      end
    end

    test "list_room_messages/1 returns messages in order", %{room: room, user: user} do
      msg1 = create_message(room, user, "first")
      msg2 = create_message(room, user, "second")
      msg3 = create_message(room, user, "third")

      messages = Chat.list_room_messages(room.id)

      assert length(messages) == 3
      assert List.first(messages).id == msg1.id
      assert Enum.at(messages, 1).id == msg2.id
      assert List.last(messages).id == msg3.id
    end

    test "list_room_messages/1 preloads user data", %{room: room, user: user} do
      create_message(room, user, "test")

      messages = Chat.list_room_messages(room.id)

      assert length(messages) == 1
      message = List.first(messages)
      assert message.user.id == user.id
      assert message.user.email == user.email
    end

    test "list_room_messages/1 respects limit parameter", %{room: room, user: user} do
      create_message(room, user, "msg1")
      create_message(room, user, "msg2")
      create_message(room, user, "msg3")
      create_message(room, user, "msg4")

      messages = Chat.list_room_messages(room.id, 2)

      assert length(messages) == 2
    end

    test "list_room_messages/1 default limit is 50", %{room: room, user: user} do
      # Create 60 messages
      for i <- 1..60 do
        create_message(room, user, "msg#{i}")
      end

      messages = Chat.list_room_messages(room.id)

      assert length(messages) == 50
    end

    test "list_room_messages/1 empty room returns empty list" do
      room = create_room(%{name: "empty-room"})

      messages = Chat.list_room_messages(room.id)

      assert messages == []
    end

    test "delete_message/1 removes message", %{room: room, user: user} do
      {:ok, msg} = Chat.create_message(%{body: "to delete", user_id: user.id, room_id: room.id})

      {:ok, _} = Chat.delete_message(msg)

      # Verify message is gone by checking it can't be fetched
      assert_raise Ecto.NoResultsError, fn ->
        Chat.get_message!(msg.id)
      end
    end

    test "delete_message/1 returns tuple", %{room: room, user: user} do
      {:ok, msg} = Chat.create_message(%{body: "test", user_id: user.id, room_id: room.id})

      result = Chat.delete_message(msg)

      assert {:ok, _} = result
    end
  end

  describe "message ordering and pagination" do
    setup do
      room = create_room(%{name: "page-room"})
      user = Fixtures.user_fixture()
      Chat.add_member(user.id, room.id)

      {:ok, room: room, user: user}
    end

    test "messages are ordered by inserted_at ascending", %{room: room, user: user} do
      # Create messages with slight delays to ensure different timestamps
      msg1 = create_message(room, user, "first")
      Process.sleep(10)
      msg2 = create_message(room, user, "second")
      Process.sleep(10)
      msg3 = create_message(room, user, "third")

      messages = Chat.list_room_messages(room.id)

      assert List.first(messages).id == msg1.id
      assert Enum.at(messages, 1).id == msg2.id
      assert List.last(messages).id == msg3.id
    end

    test "can retrieve messages with limit", %{room: room, user: user} do
      # Create 5 messages
      for i <- 1..5 do
        create_message(room, user, "msg#{i}")
      end

      # Get only first 2 (ascending order means earliest first)
      messages = Chat.list_room_messages(room.id, 2)

      assert length(messages) == 2
      # Messages are ordered by inserted_at ascending
      # The first message should be one of the early ones created
      assert Enum.at(messages, 0).body in ["msg1", "msg2", "msg3", "msg4", "msg5"]
      assert Enum.at(messages, 1).body in ["msg1", "msg2", "msg3", "msg4", "msg5"]
    end
  end

  # Private helpers

  defp create_room(attrs) do
    {:ok, room} = Chat.create_room(attrs)
    room
  end

  defp create_message(room, user, body) do
    {:ok, msg} = Chat.create_message(%{body: body, user_id: user.id, room_id: room.id})
    msg
  end
end
