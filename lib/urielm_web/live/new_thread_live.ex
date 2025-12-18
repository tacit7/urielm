defmodule UrielmWeb.NewThreadLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Forum
  alias Urielm.Params
  alias Urielm.Forum.Thread

  @impl true
  def mount(%{"board_slug" => slug}, _session, socket) do
    board = Forum.get_board!(slug)
    user = socket.assigns.current_user

    # Check if user needs a handle before posting
    if is_nil(user.username) do
      {:ok,
       socket
       |> put_flash(:info, "Please set a username before creating a thread")
       |> redirect(to: ~p"/signup/set-handle")}
    else
      {:ok,
       socket
       |> assign(:page_title, "New Thread")
       |> assign(:board, board)
       |> assign(:thread_form, to_form(Thread.changeset(%Thread{}, %{})))}
    end
  end

  @impl true
  def handle_event("validate", %{"thread" => thread_params0}, socket) do
    changeset =
      %Thread{}
      |> Thread.changeset(Params.normalize(thread_params0))
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :thread_form, to_form(changeset))}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", %{"thread" => thread_params0}, socket) do
    %{board: board, current_user: user} = socket.assigns

    # Auto-generate slug from title
    params = Params.normalize(thread_params0)
    params_with_slug =
      if params["slug"] && params["slug"] != "" do
        params
      else
        Map.put(params, "slug", Urielm.Slugify.slugify(params["title"] || ""))
      end

    case Forum.create_thread(board.id, user.id, params_with_slug) do
      {:ok, thread} ->
        {:noreply,
         socket
         |> put_flash(:info, "Thread created successfully")
         |> redirect(to: ~p"/forum/t/#{thread.id}")}

      {:error, changeset} ->
        {:noreply, assign(socket, :thread_form, to_form(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user} current_page="" socket={@socket}>
      <div class="min-h-screen bg-base-100">
        <div class="container mx-auto px-4 py-8 max-w-2xl">
          <div class="mb-8">
            <.link navigate={~p"/forum/b/#{@board.slug}"} class="link link-hover text-sm mb-4">
              ← Back to {@board.name}
            </.link>

            <h1 class="text-4xl font-bold text-base-content mb-2">New Thread</h1>
            <p class="text-base-content/60">Start a discussion in {@board.name}</p>
          </div>

          <div class="card bg-base-200 border border-base-300">
            <div class="card-body">
              <.form for={@thread_form} phx-change="validate" phx-submit="save" class="space-y-6">
                <div>
                  <.input
                    field={@thread_form[:title]}
                    type="text"
                    label="Title"
                    placeholder="What's your thread about?"
                    class="input input-bordered w-full"
                    required
                  />
                  <%= for {msg, _opts} <- @thread_form[:title].errors do %>
                    <p class="text-error text-sm mt-1">{msg}</p>
                  <% end %>
                </div>

                <div>
                  <.input
                    field={@thread_form[:body]}
                    type="textarea"
                    label="Description"
                    placeholder="Share your thoughts... (Markdown supported)"
                    class="textarea textarea-bordered w-full min-h-80"
                    required
                  />
                  <%= for {msg, _opts} <- @thread_form[:body].errors do %>
                    <p class="text-error text-sm mt-1">{msg}</p>
                  <% end %>
                </div>

                <div class="flex gap-4 justify-end">
                  <.link
                    navigate={~p"/forum/b/#{@board.slug}"}
                    class="btn btn-ghost"
                  >
                    Cancel
                  </.link>
                  <button type="submit" class="btn btn-primary">
                    Create Thread
                  </button>
                </div>
              </.form>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
