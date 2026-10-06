defmodule UrielmWeb.SessionRevocationTest do
  use UrielmWeb.ConnCase
  import Phoenix.LiveViewTest
  require Phoenix.ChannelTest
  import Urielm.Fixtures
  alias Urielm.Accounts.Sessions

  test "logout disconnects an open LiveView and prevents reconnect", %{conn: conn} do
    user = user_fixture()
    conn = log_in_user(conn, user)
    token = get_session(conn, :session_token)
    {:ok, view, _} = live(conn, ~p"/settings")
    monitor = Process.monitor(view.pid)
    delete(conn, ~p"/auth/logout")
    assert_receive {:DOWN, ^monitor, :process, _, _}
    assert Sessions.user(token) == nil
    assert {:error, {:redirect, %{to: "/signup"}}} = live(conn, ~p"/settings")
  end

  test "a revoked session cannot submit an event even if the broadcast has not arrived", %{
    conn: conn
  } do
    user = user_fixture()
    conn = log_in_user(conn, user)
    {:ok, view, _} = live(conn, ~p"/settings")
    # Delete without broadcasting to exercise the server-side event guard.
    Sessions.delete_for_user(user.id)
    render_hook(view, "update_profile", %{"user" => %{"private_profile" => "true"}})
    assert_redirect(view, "/signin")
    refute Urielm.Accounts.get_user(user.id).private_profile
  end

  test "password changes disconnect open LiveViews on every device", %{conn: conn} do
    user = user_fixture()
    first = log_in_user(conn, user)
    second = log_in_user(build_conn(), user)
    {:ok, a, _} = live(first, ~p"/settings")
    {:ok, b, _} = live(second, ~p"/settings")
    ma = Process.monitor(a.pid)
    mb = Process.monitor(b.pid)
    assert {:ok, _} = Urielm.Accounts.update_user_password(user, %{password: "newpassword123"})
    assert_receive {:DOWN, ^ma, :process, _, _}
    assert_receive {:DOWN, ^mb, :process, _, _}
  end

  test "an idle LiveView expires without another request", %{conn: conn} do
    conn = log_in_user(conn, user_fixture())

    Urielm.Repo.update_all(Urielm.Accounts.UserSession,
      set: [expires_at: DateTime.add(DateTime.utc_now(:second), 2)]
    )

    {:ok, view, _} = live(conn, ~p"/settings")
    monitor = Process.monitor(view.pid)
    assert_receive {:DOWN, ^monitor, :process, _, _}, 3000
  end

  test "chat messages are rejected after revocation even before disconnect is processed" do
    user = user_fixture()
    token = Sessions.create(user)
    {:ok, room} = Urielm.Chat.create_room(%{name: "session-guard"})
    {:ok, _} = Urielm.Chat.add_member(user.id, room.id)
    signed = Phoenix.Token.sign(@endpoint, "user socket", token)
    {:ok, socket} = Phoenix.ChannelTest.connect(UrielmWeb.UserSocket, %{"token" => signed})

    {:ok, _, socket} =
      Phoenix.ChannelTest.subscribe_and_join(socket, UrielmWeb.RoomChannel, "room:#{room.id}")

    monitor = Process.monitor(socket.channel_pid)
    Sessions.delete_for_user(user.id)
    Phoenix.ChannelTest.push(socket, "new_message", %{body: "must not persist"})
    assert_receive {:DOWN, ^monitor, :process, _, _}
    assert Urielm.Chat.list_room_messages(room.id) == []
  end

  test "chat identity tokens cannot outlive the underlying session" do
    user = user_fixture()
    token = Sessions.create(user)
    signed = Phoenix.Token.sign(@endpoint, "user socket", token)
    assert {:ok, socket} = Phoenix.ChannelTest.connect(UrielmWeb.UserSocket, %{"token" => signed})
    assert UrielmWeb.UserSocket.id(socket) == Sessions.topic(token)
    Sessions.revoke(token)
    assert :error = Phoenix.ChannelTest.connect(UrielmWeb.UserSocket, %{"token" => signed})
    legacy = Phoenix.Token.sign(@endpoint, "user socket", user.id)
    assert :error = Phoenix.ChannelTest.connect(UrielmWeb.UserSocket, %{"token" => legacy})
  end
end
