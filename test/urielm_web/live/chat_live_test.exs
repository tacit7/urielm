defmodule UrielmWeb.ChatLiveTest do
  use UrielmWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Urielm.Fixtures

  alias Urielm.Chat

  test "renders the chat workspace for a signed-in member", %{conn: conn} do
    user = user_fixture()

    {:ok, view, _html} = live(log_in_user(conn, user), ~p"/chat")

    assert has_element?(view, "#chat-page")
    assert has_element?(view, "#chat-room-sidebar")
    assert has_element?(view, "#chat-room-list")
    assert has_element?(view, "#chat-conversation")
    assert has_element?(view, "#chat-empty-state")
    refute has_element?(view, "#create-room-button")
  end

  test "only lists rooms the signed-in user belongs to", %{conn: conn} do
    user = user_fixture()
    other_user = user_fixture()
    visible_room = room_fixture(%{name: "visible-room"})
    hidden_room = room_fixture(%{name: "hidden-room"})

    Chat.add_member(user.id, visible_room.id)
    Chat.add_member(other_user.id, hidden_room.id)

    {:ok, view, _html} = live(log_in_user(conn, user), ~p"/chat")

    assert has_element?(view, "#chat-room-#{visible_room.id}")
    refute has_element?(view, "#chat-room-#{hidden_room.id}")
  end

  test "does not auto-join a user from direct room navigation", %{conn: conn} do
    user = user_fixture()
    room = room_fixture(%{name: "private-room"})

    assert {:error, {:live_redirect, %{to: "/chat", flash: %{"error" => "Chat room not found"}}}} =
             live(log_in_user(conn, user), ~p"/chat?room_id=#{room.id}")

    refute Chat.member?(user.id, room.id)
  end

  test "renders the shared create-room form for an admin", %{conn: conn} do
    admin = admin_fixture()

    {:ok, view, _html} = live(log_in_user(conn, admin), ~p"/chat")

    assert has_element?(view, "#create-room-button")
    assert has_element?(view, "#create-room-form")
    assert has_element?(view, ~s(#create-room-form input[name="room[name]"]))
    assert has_element?(view, ~s(#create-room-form textarea[name="room[description]"]))
  end

  test "creates and selects a room from the admin form", %{conn: conn} do
    admin = admin_fixture()
    room_name = "liveview-room-#{System.unique_integer([:positive])}"

    {:ok, view, _html} = live(log_in_user(conn, admin), ~p"/chat")

    view
    |> form("#create-room-form", room: %{name: room_name, description: "LiveView test room"})
    |> render_submit()

    room = Chat.get_room_by_name(room_name)

    assert room
    assert_redirect(view, ~p"/chat?room_id=#{room.id}")
  end

  test "fixes selected room access surviving membership removal", %{conn: conn} do
    user = user_fixture()
    room = room_fixture(%{name: "revoked-room"})
    Chat.add_member(user.id, room.id)

    {:ok, _message} =
      Chat.create_message(%{user_id: user.id, room_id: room.id, body: "Private history"})

    {:ok, view, _html} = live(log_in_user(conn, user), ~p"/chat?room_id=#{room.id}")
    refute has_element?(view, "#chat-empty-state")

    Chat.remove_member(user.id, room.id)
    assert_patch(view, ~p"/chat")
    assert has_element?(view, "#chat-empty-state")
    refute has_element?(view, "#chat-room-#{room.id}")
    refute has_element?(view, "[data-name=ChatWindow]")
  end

  test "fixes a stale send after membership removal without a broadcast", %{conn: conn} do
    user = user_fixture()
    room = room_fixture(%{name: "stale-room"})
    Chat.add_member(user.id, room.id)
    {:ok, view, _html} = live(log_in_user(conn, user), ~p"/chat?room_id=#{room.id}")

    membership =
      Urielm.Repo.get_by!(Urielm.Chat.RoomMembership, user_id: user.id, room_id: room.id)

    Urielm.Repo.delete!(membership)

    render_hook(view, "send_message", %{body: "Should fail"})
    assert Chat.list_room_messages(room.id) == []
    assert_patch(view, ~p"/chat")
    assert has_element?(view, "#chat-empty-state")
  end

  test "ignores a forged send with no selected room", %{conn: conn} do
    user = user_fixture()
    {:ok, view, _html} = live(log_in_user(conn, user), ~p"/chat")
    render_hook(view, "send_message", %{body: "Should fail"})
    assert has_element?(view, "#chat-empty-state")
  end

  test "rechecks silenced status while retaining read access", %{conn: conn} do
    user = user_fixture()
    room = room_fixture(%{name: "silenced-room"})
    Chat.add_member(user.id, room.id)
    {:ok, view, _html} = live(log_in_user(conn, user), ~p"/chat?room_id=#{room.id}")

    user
    |> Ecto.Changeset.change(%{silenced_at: DateTime.utc_now(:second)})
    |> Urielm.Repo.update!()

    render_hook(view, "send_message", %{body: "Should fail"})
    assert Chat.list_room_messages(room.id) == []
    refute has_element?(view, "#chat-empty-state")
    assert has_element?(view, "#chat-room-#{room.id}")
  end

  test "sends as the signed-in member despite forged identity attributes", %{conn: conn} do
    user = user_fixture()
    other = user_fixture()
    room = room_fixture(%{name: "send-room"})
    Chat.add_member(user.id, room.id)
    {:ok, view, _html} = live(log_in_user(conn, user), ~p"/chat?room_id=#{room.id}")

    render_hook(view, "send_message", %{body: "Allowed", user_id: other.id, room_id: 0})
    assert [%{user_id: user_id, body: "Allowed"}] = Chat.list_room_messages(room.id)
    assert user_id == user.id
  end

  test "fixes oversized room IDs crashing room navigation", %{conn: conn} do
    user = user_fixture()
    room_id = String.duplicate("9", 100)

    assert {:error, {:live_redirect, %{to: "/chat"}}} =
             live(log_in_user(conn, user), ~p"/chat?room_id=#{room_id}")
  end

  test "rejects nonbinary room IDs without crashing", %{conn: conn} do
    user = user_fixture()

    assert {:error, {:live_redirect, %{to: "/chat"}}} =
             live(log_in_user(conn, user), "/chat?room_id[]=1")
  end

  defp room_fixture(attrs) do
    {:ok, room} = Chat.create_room(attrs)
    room
  end
end
