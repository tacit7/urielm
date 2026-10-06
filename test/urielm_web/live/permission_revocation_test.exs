defmodule UrielmWeb.PermissionRevocationTest do
  use UrielmWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  alias Urielm.{Fixtures, Forum, Repo}

  test "fixes demoted administrators creating tags from an open admin page", %{conn: conn} do
    admin = Fixtures.admin_fixture()
    {:ok, view, _} = live(log_in_user(conn, admin), "/admin/tags")
    assert has_element?(view, "#admin-tag-form")

    admin |> Ecto.Changeset.change(is_admin: false) |> Repo.update!()

    result =
      view |> form("#admin-tag-form", tag: %{name: "Revoked", slug: "revoked"}) |> render_submit()

    assert Forum.get_tag_by_slug("revoked") == nil
    assert_redirect(view, "/")
    assert {:error, {:redirect, %{to: "/"}}} = result
  end

  test "fixes stale moderator permissions on an open public thread", %{conn: conn} do
    moderator =
      Fixtures.user_fixture() |> Ecto.Changeset.change(is_moderator: true) |> Repo.update!()

    thread = Fixtures.thread_fixture()
    {:ok, view, _} = live(log_in_user(conn, moderator), "/forum/t/#{thread.id}")

    moderator |> Ecto.Changeset.change(is_moderator: false) |> Repo.update!()
    render_click(view, "lock_thread")

    refute Forum.get_thread!(thread.id).is_locked
  end

  test "fixes inactive accounts navigating through live patch", %{conn: conn} do
    user = Fixtures.user_fixture()
    {:ok, view, _} = live(log_in_user(conn, user), "/videos")

    user |> Ecto.Changeset.change(active: false) |> Repo.update!()
    render_patch(view, "/videos?sort=oldest")
    assert_redirect(view, "/signin")
  end

  test "fixes demoted administrators creating chat rooms", %{conn: conn} do
    admin = Fixtures.admin_fixture()
    {:ok, view, _} = live(log_in_user(conn, admin), "/chat")
    admin |> Ecto.Changeset.change(is_admin: false) |> Repo.update!()

    view
    |> form("#create-room-form", room: %{name: "Revoked room", description: "Denied"})
    |> render_submit()

    refute Repo.get_by(Urielm.Chat.Room, name: "Revoked room")
  end

  test "moderator revocation disconnects an already open LiveView", %{conn: conn} do
    moderator =
      Fixtures.user_fixture() |> Ecto.Changeset.change(is_moderator: true) |> Repo.update!()

    conn = log_in_user(conn, moderator)
    {:ok, view, _} = live(conn, "/settings")
    monitor = Process.monitor(view.pid)

    assert {:ok, _} = Urielm.Accounts.revoke_moderator(moderator, Fixtures.admin_fixture())
    assert_receive {:DOWN, ^monitor, :process, _, _}
    assert {:error, {:redirect, %{to: "/signup"}}} = live(conn, "/settings")
  end

  test "fixes inactive accounts being authenticated by the HTTP plug", %{conn: conn} do
    user = Fixtures.user_fixture()
    conn = log_in_user(conn, user)
    user |> Ecto.Changeset.change(active: false) |> Repo.update!()

    conn = UrielmWeb.Plugs.Auth.call(conn, :fetch_current_user)
    assert conn.assigns.current_user == nil
    assert conn.private.plug_session_info == :drop
  end

  test "fixes inactive accounts mounting authenticated pages", %{conn: conn} do
    user = Fixtures.user_fixture()
    conn = log_in_user(conn, user)
    user |> Ecto.Changeset.change(active: false) |> Repo.update!()

    assert {:halt, socket} =
             UrielmWeb.UserAuth.on_mount(
               :ensure_authenticated,
               %{},
               %{"session_token" => get_session(conn, :session_token)},
               %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}}}
             )

    assert {:redirect, %{to: "/signin"}} = socket.redirected
  end
end
