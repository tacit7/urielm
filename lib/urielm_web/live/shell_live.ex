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
    |> assign_page_metadata(live_action)
  end

  defp assign_page_metadata(socket, :home) do
    assign(socket,
      page_title: "Practical AI Learning",
      meta_description:
        "Urielm is a public learning platform with practical AI tutorials, structured courses, reusable prompts, and developer community discussions.",
      canonical_url: "https://urielm.dev/"
    )
  end

  defp assign_page_metadata(socket, :videos) do
    assign(socket,
      page_title: "Videos",
      meta_description:
        "Watch practical AI walkthroughs, developer tutorials, and quick videos from Urielm.",
      canonical_url: "https://urielm.dev/videos"
    )
  end

  defp assign_page_metadata(socket, :code_kata) do
    assign(socket,
      page_title: "Code Kata",
      meta_description:
        "Code Kata is a focused desktop app for practicing Python and JavaScript problems, tracking mastery, and reviewing what needs another pass.",
      canonical_url: "https://urielm.dev/code-kata"
    )
  end

  defp assign_page_metadata(socket, _live_action), do: socket

  defp page_name_for_action(:home), do: "home"
  defp page_name_for_action(:blog_index), do: "blog"
  defp page_name_for_action(:blog_show), do: "blog"
  defp page_name_for_action(:prompts), do: "prompts"
  defp page_name_for_action(:prompt_show), do: "prompts"
  defp page_name_for_action(:videos), do: "videos"
  defp page_name_for_action(:courses), do: "courses"
  defp page_name_for_action(:course), do: "courses"
  defp page_name_for_action(:lesson), do: "courses"
  defp page_name_for_action(:video), do: "videos"
  defp page_name_for_action(:code_kata), do: "code-kata"
  defp page_name_for_action(:themes), do: "home"
  defp page_name_for_action(:user_profile), do: "profile"
  defp page_name_for_action(_), do: "home"

  @impl true
  def render(assigns) do
    ~H"""
    <UrielmWeb.Layouts.app
      flash={@flash}
      current_user={@current_user}
      current_page={@current_page}
      socket={@socket}
      unread_notification_count={@unread_notification_count}
    >
      {live_render(@socket, child_module(@live_action),
        id: "page-#{@live_action}",
        session: %{
          "current_user_id" => current_user_id(@current_user),
          "child_params" => @child_params
        }
      )}
    </UrielmWeb.Layouts.app>
    """
  end

  defp child_module(:home), do: UrielmWeb.HomeLive
  defp child_module(:blog_index), do: UrielmWeb.BlogLive
  defp child_module(:blog_show), do: UrielmWeb.BlogLive
  defp child_module(:prompts), do: UrielmWeb.PromptsLive
  defp child_module(:prompt_show), do: UrielmWeb.PromptLive
  defp child_module(:videos), do: UrielmWeb.VideosLive
  defp child_module(:courses), do: UrielmWeb.CoursesLive
  defp child_module(:course), do: UrielmWeb.CourseLive
  defp child_module(:lesson), do: UrielmWeb.LessonLive
  defp child_module(:video), do: UrielmWeb.VideoLive
  defp child_module(:code_kata), do: UrielmWeb.CodeKataLive
  defp child_module(:themes), do: UrielmWeb.ThemesLive
  defp child_module(:user_profile), do: UrielmWeb.UserProfileLive
  defp child_module(_), do: UrielmWeb.HomeLive

  defp current_user_id(nil), do: nil
  defp current_user_id(user), do: user.id
end
