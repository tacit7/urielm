defmodule UrielmWeb.SignupEmailLiveTest do
  use UrielmWeb.ConnCase

  setup do
    previous = Application.fetch_env(:urielm, :email_signup_enabled)
    Application.put_env(:urielm, :email_signup_enabled, true)

    on_exit(fn ->
      case previous do
        {:ok, value} -> Application.put_env(:urielm, :email_signup_enabled, value)
        :error -> Application.delete_env(:urielm, :email_signup_enabled)
      end
    end)

    :ok
  end

  import Phoenix.LiveViewTest

  alias Urielm.Accounts
  alias Urielm.Accounts.UserSession
  alias Urielm.Repo
  alias UrielmWeb.SignupEmailLive

  setup do
    old = Application.get_env(:urielm, :rate_limit_bypass)
    Application.put_env(:urielm, :rate_limit_bypass, false)
    :sys.replace_state(Urielm.RateLimiter, fn _ -> %{} end)

    on_exit(fn ->
      Application.put_env(:urielm, :rate_limit_bypass, old)
      :sys.replace_state(Urielm.RateLimiter, fn _ -> %{} end)
    end)

    :ok
  end

  test "fixes signup budget bypass through LiveView and reconnects", %{conn: conn} do
    params = %{"email" => "shared@example.com", "password" => "short"}

    for _ <- 1..3 do
      assert post(conn, ~p"/auth/signup", params).status == 422
    end

    for i <- 1..2 do
      {:ok, view, _} = live(with_peer(conn, {198, 51, 100, i}), ~p"/signup/email")

      view
      |> form("#signup-email-form", %{email: " SHARED@example.com ", password: "password123"})
      |> render_submit()

      assert has_element?(view, "#signup-email-error", "Too many attempts")
    end

    refute Urielm.Accounts.get_user_by_email(params["email"])
  end

  test "fixes IP budget bypass when changing emails and entry points", %{conn: conn} do
    for i <- 1..5 do
      {:ok, view, _} = live(conn, ~p"/signup/email")

      view
      |> form("#signup-email-form", %{email: "ip#{i}@example.com", password: "short"})
      |> render_submit()

      assert has_element?(view, "#signup-email-error", "at least 8 characters")
    end

    assert post(conn, ~p"/auth/signup", %{email: "new@example.com", password: "short"}).status ==
             429
  end

  test "direct peers cannot reset signup IP budget using forwarded headers", %{conn: conn} do
    conn = with_peer(conn, {198, 51, 100, 10})

    for i <- 1..5 do
      attempt = put_req_header(conn, "x-forwarded-for", "203.0.113.#{i}")

      assert post(attempt, ~p"/auth/signup", %{email: "direct#{i}@example.com", password: "short"}).status ==
               422
    end

    {:ok, view, _} =
      live(put_req_header(conn, "x-forwarded-for", "203.0.113.99"), ~p"/signup/email")

    view
    |> form("#signup-email-form", %{email: "directlive@example.com", password: "password123"})
    |> render_submit()

    assert has_element?(view, "#signup-email-error", "Too many attempts")
    refute Urielm.Accounts.get_user_by_email("directlive@example.com")
  end

  test "configured CIDR proxy shares normalized forwarded IP across transports", %{conn: conn} do
    old = Application.get_env(:urielm, :trusted_proxy_cidrs)
    Application.put_env(:urielm, :trusted_proxy_cidrs, ["10.0.0.0/24"])

    on_exit(fn ->
      if old,
        do: Application.put_env(:urielm, :trusted_proxy_cidrs, old),
        else: Application.delete_env(:urielm, :trusted_proxy_cidrs)
    end)

    conn = with_peer(conn, {10, 0, 0, 1})

    for i <- 1..5 do
      {:ok, view, _} =
        live(
          put_req_header(conn, "x-forwarded-for", "203.0.113.#{i}, 198.51.100.20"),
          ~p"/signup/email"
        )

      view
      |> form("#signup-email-form", %{email: "proxy#{i}@example.com", password: "short"})
      |> render_submit()

      assert has_element?(view, "#signup-email-error", "at least 8 characters")
    end

    assert conn
           |> put_req_header("x-forwarded-for", "203.0.113.99, 198.51.100.20")
           |> post(~p"/auth/signup", %{email: "proxynew@example.com", password: "short"})
           |> Map.fetch!(:status) == 429

    assert conn
           |> put_req_header("x-forwarded-for", "198.51.100.21")
           |> post(~p"/auth/signup", %{email: "otherclient@example.com", password: "short"})
           |> Map.fetch!(:status) == 422
  end

  test "repeated LiveView attempts exhaust the identifier budget", %{conn: conn} do
    {:ok, view, _} = live(conn, ~p"/signup/email")

    for _ <- 1..3 do
      view
      |> form("#signup-email-form", %{email: "repeat@example.com", password: "short"})
      |> render_submit()

      assert has_element?(view, "#signup-email-error", "at least 8 characters")
    end

    view
    |> form("#signup-email-form", %{email: "repeat@example.com", password: "password123"})
    |> render_submit()

    assert has_element?(view, "#signup-email-error", "Too many attempts")
    refute Urielm.Accounts.get_user_by_email("repeat@example.com")
  end

  test "a permitted LiveView registration still creates an account", %{conn: conn} do
    {:ok, view, _} = live(conn, ~p"/signup/email")

    view
    |> form("#signup-email-form", %{email: "permitted@example.com", password: "password123"})
    |> render_submit()

    assert Urielm.Accounts.get_user_by_email("permitted@example.com")
    assert_redirect(view)
  end

  for {label, assigns} <- [
        {"absent", %{}},
        {"nil", %{signup_binding: nil}},
        {"empty", %{signup_binding: ""}},
        {"short", %{signup_binding: String.duplicate("a", 42)}},
        {"long", %{signup_binding: String.duplicate("a", 44)}},
        {"nonbinary", %{signup_binding: 43}}
      ] do
    test "rejects #{label} browser binding before persisting an account" do
      email = unquote(label) <> "-binding@example.com"
      session_count = Repo.aggregate(UserSession, :count)
      socket = signup_socket(unquote(Macro.escape(assigns)))

      assert {:noreply, socket} =
               SignupEmailLive.handle_event(
                 "submit",
                 %{"email" => email, "password" => "password123"},
                 socket
               )

      refute Accounts.get_user_by_email(email)
      assert Repo.aggregate(UserSession, :count) == session_count
      assert {:redirect, %{to: "/signup"}} = socket.redirected
    end
  end

  test "a forged submit binding cannot replace a missing browser binding" do
    email = "forged-binding@example.com"
    session_count = Repo.aggregate(UserSession, :count)

    assert {:noreply, socket} =
             SignupEmailLive.handle_event(
               "submit",
               %{
                 "email" => email,
                 "password" => "password123",
                 "signup_binding" => String.duplicate("a", 43)
               },
               signup_socket(%{signup_binding: nil})
             )

    refute Accounts.get_user_by_email(email)
    assert Repo.aggregate(UserSession, :count) == session_count
    assert {:redirect, %{to: "/signup"}} = socket.redirected
  end

  defp signup_socket(assigns) do
    %Phoenix.LiveView.Socket{endpoint: UrielmWeb.Endpoint, router: UrielmWeb.Router}
    |> Phoenix.Component.assign(%{registration_ip: "198.51.100.10", loading: false})
    |> Phoenix.Component.assign(assigns)
  end

  defp with_peer(conn, address) do
    {adapter, payload} = conn.adapter
    payload = Map.update!(payload, :peer_data, &Map.put(&1, :address, address))
    %{conn | remote_ip: address, adapter: {adapter, payload}}
  end
end
