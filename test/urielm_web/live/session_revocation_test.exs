defmodule UrielmWeb.SessionRevocationTest do
  use UrielmWeb.ConnCase
  import Phoenix.LiveViewTest
  require Phoenix.ChannelTest
  import Urielm.Fixtures
  alias Urielm.Accounts.Sessions

  test "rendered LiveView sessions and chat props do not contain authentication credentials", %{
    conn: conn
  } do
    user = user_fixture()
    conn = log_in_user(conn, user)
    token = get_session(conn, :session_token)
    {:ok, shell, _} = live(conn, ~p"/")
    document = LazyHTML.from_document(render(shell))

    signed_sessions =
      document |> LazyHTML.query("[data-phx-session]") |> LazyHTML.attribute("data-phx-session")

    assert Enum.any?(signed_sessions, &(&1 != ""))

    for signed <- signed_sessions, signed != "" do
      {:ok, decoded} = Phoenix.LiveView.Static.verify_token(@endpoint, signed)
      refute inspect(decoded) =~ token
    end

    {:ok, room} = Urielm.Chat.create_room(%{name: "credential-exposure"})
    {:ok, _} = Urielm.Chat.add_member(user.id, room.id)
    {:ok, chat, _} = live(conn, ~p"/chat?room_id=#{room.id}")

    [props] =
      render(chat)
      |> LazyHTML.from_document()
      |> LazyHTML.query("[data-name='ChatWindow']")
      |> LazyHTML.attribute("data-props")

    refute Map.has_key?(Jason.decode!(props), "socketToken")
    refute props =~ token
  end

  test "chat rejects a copied signed token without an authenticated cookie" do
    token = Sessions.create(user_fixture())
    signed = Phoenix.Token.sign(@endpoint, "user socket", token)
    assert :error = Phoenix.ChannelTest.connect(UrielmWeb.UserSocket, %{"token" => signed})
  end

  test "socket transport requires the signed session cookie and matching CSRF token", %{
    conn: conn
  } do
    conn = conn |> log_in_user(user_fixture()) |> get(~p"/chat")
    cookie = conn.resp_cookies["_urielm_key"].value

    [csrf] =
      conn.resp_body
      |> LazyHTML.from_document()
      |> LazyHTML.query("meta[name='csrf-token']")
      |> LazyHTML.attribute("content")

    transport = fn csrf ->
      conn =
        build_conn()
        |> put_req_cookie("_urielm_key", cookie)
        |> Map.put(:params, %{"_csrf_token" => csrf})

      Phoenix.Socket.Transport.connect_info(conn, @endpoint,
        session: {:mfa, {@endpoint, :session_options, []}}
      )
    end

    good = transport.(csrf)
    assert good.session["session_token"]
    assert {:ok, _} = Phoenix.ChannelTest.connect(UrielmWeb.UserSocket, %{}, connect_info: good)

    for invalid <- [nil, "wrong"] do
      info = transport.(invalid)
      assert info.session == nil
      assert :error = Phoenix.ChannelTest.connect(UrielmWeb.UserSocket, %{}, connect_info: info)
    end
  end

  test "suspension disconnects open pages and prevents chat access", %{conn: conn} do
    user = user_fixture()
    admin = admin_fixture()
    conn = log_in_user(conn, user)
    token = get_session(conn, :session_token)
    {:ok, view, _} = live(conn, ~p"/settings")
    monitor = Process.monitor(view.pid)
    assert {:ok, _} = Urielm.Accounts.suspend_user(user, admin, reason: "security test")
    assert_receive {:DOWN, ^monitor, :process, _, _}
    refute Sessions.allowed?(token)

    assert :error =
             Phoenix.ChannelTest.connect(UrielmWeb.UserSocket, %{},
               connect_info: %{session: %{"session_token" => token}}
             )
  end

  test "a session revoked before channel join is denied cleanly" do
    token = Sessions.create(user_fixture())

    {:ok, socket} =
      Phoenix.ChannelTest.connect(UrielmWeb.UserSocket, %{},
        connect_info: %{session: %{"session_token" => token}}
      )

    Sessions.revoke(token)
    assert {:error, %{reason: "unauthorized"}} = UrielmWeb.RoomChannel.join("room:1", %{}, socket)
  end

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

    {:ok, socket} =
      Phoenix.ChannelTest.connect(UrielmWeb.UserSocket, %{},
        connect_info: %{session: %{"session_token" => token}}
      )

    {:ok, _, socket} =
      Phoenix.ChannelTest.subscribe_and_join(socket, UrielmWeb.RoomChannel, "room:#{room.id}")

    monitor = Process.monitor(socket.channel_pid)
    Sessions.delete_for_user(user.id)
    Phoenix.ChannelTest.push(socket, "new_message", %{body: "must not persist"})
    assert_receive {:DOWN, ^monitor, :process, _, _}
    assert Urielm.Chat.list_room_messages(room.id) == []
  end

  test "chat cookie sessions cannot outlive their server record" do
    user = user_fixture()
    token = Sessions.create(user)

    assert {:ok, socket} =
             Phoenix.ChannelTest.connect(UrielmWeb.UserSocket, %{},
               connect_info: %{session: %{"session_token" => token}}
             )

    assert UrielmWeb.UserSocket.id(socket) == Sessions.topic(token)
    Sessions.revoke(token)

    assert :error =
             Phoenix.ChannelTest.connect(UrielmWeb.UserSocket, %{},
               connect_info: %{session: %{"session_token" => token}}
             )

    legacy = Phoenix.Token.sign(@endpoint, "user socket", user.id)
    assert :error = Phoenix.ChannelTest.connect(UrielmWeb.UserSocket, %{"token" => legacy})
  end
end
