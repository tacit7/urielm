defmodule UrielmWeb.ShellLive do
  @moduledoc """
  Persistent shell LiveView that keeps the navbar mounted across page navigations.
  Child pages render inside this shell via live_render/3.
  """
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, live_action, params) do
    socket
    |> assign(:live_action, live_action)
    |> assign(:current_page, page_name_for_action(live_action))
    |> assign(:child_params, params)
  end

  defp page_name_for_action(:home), do: "home"
  defp page_name_for_action(:blog_index), do: "blog"
  defp page_name_for_action(:blog_show), do: "blog"
  defp page_name_for_action(:prompts), do: "prompts"
  defp page_name_for_action(:prompt_show), do: "prompts"
  defp page_name_for_action(:courses), do: "videos"
  defp page_name_for_action(:course), do: "videos"
  defp page_name_for_action(:lesson), do: "videos"
  defp page_name_for_action(:video), do: "videos"
  defp page_name_for_action(:themes), do: "home"
  defp page_name_for_action(:forum), do: "community"
  defp page_name_for_action(:board), do: "community"
  defp page_name_for_action(:thread), do: "community"
  defp page_name_for_action(:search), do: "community"
  defp page_name_for_action(:user_profile), do: "community"
  defp page_name_for_action(_), do: "home"

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100 font-sans text-base-content antialiased">
      <div id="navbar-container" phx-update="ignore" phx-hook="NavbarActiveLinks">
        <.Navbar
          socket={@socket}
          currentPage={@current_page}
          currentUser={serialize_user(@current_user)}
        />
      </div>

      <main class="pt-16">
        <%= live_render(@socket, child_module(@live_action),
          id: "page-#{@live_action}",
          session: %{
            "current_user_id" => current_user_id(@current_user),
            "child_params" => @child_params
          }
        ) %>
      </main>

      <UrielmWeb.Layouts.flash_group flash={@flash} />
    </div>
    """
  end

  defp child_module(:home), do: UrielmWeb.HomeLive
  defp child_module(:blog_index), do: UrielmWeb.BlogLive
  defp child_module(:blog_show), do: UrielmWeb.BlogLive
  defp child_module(:prompts), do: UrielmWeb.PromptsLive
  defp child_module(:prompt_show), do: UrielmWeb.PromptLive
  defp child_module(:courses), do: UrielmWeb.CoursesLive
  defp child_module(:course), do: UrielmWeb.CourseLive
  defp child_module(:lesson), do: UrielmWeb.LessonLive
  defp child_module(:video), do: UrielmWeb.VideoLive
  defp child_module(:themes), do: UrielmWeb.ThemesLive
  defp child_module(:forum), do: UrielmWeb.ForumLive
  defp child_module(:board), do: UrielmWeb.BoardLive
  defp child_module(:thread), do: UrielmWeb.ThreadLive
  defp child_module(:search), do: UrielmWeb.SearchLive
  defp child_module(:user_profile), do: UrielmWeb.UserProfileLive
  defp child_module(_), do: UrielmWeb.HomeLive

  defp current_user_id(nil), do: nil
  defp current_user_id(user), do: user.id

  defp serialize_user(nil), do: nil

  defp serialize_user(user) do
    %{
      id: to_string(user.id),
      email: user.email,
      name: user.name,
      username: user.username,
      avatarUrl: user.avatar_url,
      isAdmin: user.is_admin || false
    }
  end
end
