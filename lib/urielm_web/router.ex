defmodule UrielmWeb.Router do
  use UrielmWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_cookies
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {UrielmWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug UrielmWeb.Plugs.Theme
    plug UrielmWeb.Plugs.Auth, :fetch_current_user
  end

  pipeline :require_auth do
    plug UrielmWeb.Plugs.Auth, :require_authenticated_user
  end

  pipeline :require_admin do
    plug UrielmWeb.Plugs.Auth, :require_authenticated_user
    plug UrielmWeb.Plugs.Auth, :require_admin
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # OAuth authentication routes
  scope "/auth", UrielmWeb do
    pipe_through :browser

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
    post "/:provider/callback", AuthController, :callback
    delete "/logout", AuthController, :delete

    # Email/password authentication
    post "/signup", AuthController, :signup
    post "/signin", AuthController, :signin
  end

  scope "/", UrielmWeb do
    pipe_through :browser

    live_session :default do
      live "/", HomeLive
      live "/romanov-prompts", ReferencesLive
      live "/prompts/:id", PromptLive
      live "/courses/:course_slug", CourseLive
      live "/courses/:course_slug/lessons/:lesson_slug", LessonLive
      live "/themes", ThemesLive
      live "/forum", ForumLive
      live "/forum/b/:board_slug", BoardLive
      live "/forum/t/:thread_id", ThreadLive
      live "/forum/search", SearchLive
    end

    get "/blog", PostController, :index
    get "/blog/:slug", PostController, :show

    live_session :authenticated,
      on_mount: [{UrielmWeb.UserAuth, :ensure_authenticated}] do
      live "/profile", ProfileLive
      live "/settings", SettingsLive
      live "/chat", ChatLive
      live "/forum/b/:board_slug/new", NewThreadLive
      live "/saved", SavedThreadsLive
      live "/notifications", NotificationsLive
    end

    live_session :admin,
      on_mount: [{UrielmWeb.UserAuth, :ensure_authenticated}] do
      live "/admin/trust-levels", Admin.TrustLevelSettingsLive
      live "/admin/moderation", Admin.ModerationQueueLive
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", UrielmWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:urielm, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: UrielmWeb.Telemetry
    end
  end
end
