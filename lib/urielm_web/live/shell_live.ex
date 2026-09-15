defmodule UrielmWeb.ShellLive do
  @moduledoc """
  Persistent shell LiveView that keeps the navbar mounted across page navigations.
  Child pages render inside this shell via live_render/3.
  """
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias UrielmWeb.SEO

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket = apply_action(socket, socket.assigns.live_action, params)

    maybe_raise_not_found!(socket)
    {:noreply, socket}
  end

  defp apply_action(socket, live_action, params) do
    {status, metadata} = SEO.metadata(live_action, params, socket.assigns[:current_user])

    socket
    |> assign(:live_action, live_action)
    |> assign(:current_page, page_name_for_action(live_action))
    |> assign(:child_params, params)
    |> assign(:not_found?, status == :not_found)
    |> assign(metadata)
    |> assign(:json_ld, SEO.json_ld(metadata))
  end

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
    assigns = assign(assigns, :seo_head, SEO.head_payload(assigns))

    ~H"""
    <UrielmWeb.Layouts.app
      flash={@flash}
      current_user={@current_user}
      current_page={@current_page}
      socket={@socket}
      unread_notification_count={@unread_notification_count}
      seo={@seo_head}
    >
      <%= if @not_found? do %>
        <section id="page-not-found" class="ui-page-shell py-16">
          <h1 class="ui-section-title">Page not found</h1>
          <p class="mt-4 text-base-content/65">This page is unavailable or has been removed.</p>
          <.link id="not-found-home" navigate={~p"/"} class="btn btn-primary mt-6">Go home</.link>
        </section>
      <% else %>
        {live_render(@socket, child_module(@live_action),
          id: "page-#{@live_action}",
          session: %{
            "current_user_id" => current_user_id(@current_user),
            "child_params" => @child_params
          }
        )}
      <% end %>
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

  defp maybe_raise_not_found!(%{assigns: %{not_found?: true}} = socket) do
    unless connected?(socket) do
      raise Phoenix.Router.NoRouteError,
        conn: socket.private.connect_info,
        router: UrielmWeb.Router
    end
  end

  defp maybe_raise_not_found!(_socket), do: :ok
end
