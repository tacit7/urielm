defmodule UrielmWeb.PromptLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Content
  alias Urielm.Params
  alias Urielm.Content.Comment

  @impl true
  def mount(params, session, socket) do
    # Handle both direct mount and child mount via live_render
    child_params = case params do
      :not_mounted_at_router -> session["child_params"] || %{}
      params -> params
    end

    id = child_params["id"]
    prompt = Content.get_prompt_with_comments(String.to_integer(id))

    {:ok,
     socket
     |> assign(:page_title, prompt.title)
     |> assign(:prompt, prompt)
     |> assign(:comment_changeset, Content.change_comment(%Comment{}))
     |> assign(:comment_form, to_form(Content.change_comment(%Comment{})))}
  end

  @impl true
  def handle_event("comment_focus", _params, socket) do
    %{current_user: user} = socket.assigns

    case user do
      nil ->
        {:noreply, put_flash(socket, :info, "Sign in to comment")}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("save_comment", %{"comment" => comment_params0}, socket) do
    %{current_user: user, prompt: prompt} = socket.assigns

    case user do
      nil ->
        {:noreply, put_flash(socket, :error, "Sign in to comment")}

      user ->
        comment_data =
          Map.merge(Params.normalize(comment_params0), %{
            "user_id" => user.id,
            "prompt_id" => prompt.id
          })

        case Content.create_comment(comment_data) do
          {:ok, _comment} ->
            updated_prompt = Content.get_prompt_with_comments(prompt.id)

            {:noreply,
             socket
             |> assign(:prompt, updated_prompt)
             |> assign(:comment_form, to_form(Content.change_comment(%Comment{})))
             |> put_flash(:info, "Comment posted")}

          {:error, changeset} ->
            {:noreply, assign(socket, :comment_form, to_form(changeset))}
        end
    end
  end

  @impl true
  def handle_event("delete_comment", %{"id" => comment_id}, socket) do
    %{current_user: user, prompt: prompt} = socket.assigns

    comment = Content.get_comment!(String.to_integer(comment_id))

    if user && (comment.user_id == user.id or user.is_admin) do
      case Content.delete_comment(comment) do
        {:ok, _} ->
          updated_prompt = Content.get_prompt_with_comments(prompt.id)
          {:noreply, assign(socket, :prompt, updated_prompt)}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to delete comment")}
      end
    else
      {:noreply, put_flash(socket, :error, "Not authorized")}
    end
  end

  @impl true
  def handle_event("toggle_like", %{"id" => _id}, socket) do
    %{current_user: user, prompt: prompt} = socket.assigns

    case user do
      nil ->
        {:noreply, put_flash(socket, :error, "Sign in to like prompts")}

      user ->
        handle_toggle_like(user, prompt.id, socket)
    end
  end

  @impl true
  def handle_event("toggle_save", %{"id" => _id}, socket) do
    %{current_user: user, prompt: prompt} = socket.assigns

    case user do
      nil ->
        {:noreply, put_flash(socket, :error, "Sign in to save prompts")}

      user ->
        handle_toggle_save(user, prompt.id, socket)
    end
  end

  # Toggle like and save handlers
  defp handle_toggle_like(user, prompt_id, socket) do
    case Content.toggle_like(user.id, prompt_id) do
      {:ok, _} ->
        updated_prompt = Content.get_prompt_with_comments(prompt_id)
        {:noreply, assign(socket, :prompt, updated_prompt)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to like prompt")}
    end
  end

  defp handle_toggle_save(user, prompt_id, socket) do
    case Content.toggle_save(user.id, prompt_id) do
      {:ok, _} ->
        updated_prompt = Content.get_prompt_with_comments(prompt_id)
        {:noreply, assign(socket, :prompt, updated_prompt)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to save prompt")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100 text-base-content pt-20">
        <div class="container mx-auto px-4 py-8">
          <div class="mb-8">
            <.link navigate={~p"/prompts"} class="link link-hover text-sm mb-4">
              ← Back to Prompts
            </.link>

            <h1 class="text-4xl font-bold text-base-content mb-4">{@prompt.title}</h1>

            <div class="flex items-center gap-4 text-sm text-base-content/60 mb-4">
              <span class="badge badge-secondary">{@prompt.category}</span>
              <span>{Calendar.strftime(@prompt.inserted_at, "%B %d, %Y")}</span>
            </div>

            <%= if @prompt.tag_records && @prompt.tag_records != [] do %>
              <div class="flex flex-wrap gap-2 mb-6">
                <%= for tag <- @prompt.tag_records do %>
                  <span class="badge badge-outline">{tag.name}</span>
                <% end %>
              </div>
            <% end %>

            <%= if @prompt.prompt do %>
              <div class="bg-base-200 rounded-lg p-6 mb-6">
                <.svelte
                  name="MarkdownRenderer"
                  props={%{content: @prompt.prompt}}
                  socket={@socket}
                />
              </div>

              <div class="flex gap-4 items-center mb-6">
                <.svelte
                  name="PromptActions"
                  props={
                    %{
                      likesCount: @prompt.likes_count,
                      savesCount: @prompt.saves_count,
                      userLiked:
                        @current_user && Content.user_liked_prompt?(@current_user.id, @prompt.id),
                      userSaved:
                        @current_user && Content.user_saved_prompt?(@current_user.id, @prompt.id),
                      promptId: to_string(@prompt.id),
                      live: @socket
                    }
                  }
                  socket={@socket}
                >
                  <button
                    id="copy-prompt-btn"
                    phx-hook="CopyToClipboard"
                    data-text={@prompt.prompt}
                    class="flex items-center gap-2 text-base-content/70 hover:text-primary transition-colors"
                    title="Copy to clipboard"
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      width="20"
                      height="20"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                    >
                      <path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2">
                      </path>
                      <rect x="8" y="2" width="8" height="4" rx="1" ry="1"></rect>
                    </svg>
                  </button>
                </.svelte>
              </div>
            <% end %>
          </div>

          <div class="divider"></div>

          <div class="max-w-2xl">
            <h2 class="text-2xl font-bold text-base-content mb-6">
              Comments ({@prompt.comments_count})
            </h2>

            <%= if @current_user do %>
              <div class="mb-8">
                <.form for={@comment_form} phx-submit="save_comment" class="space-y-4">
                  <.input
                    field={@comment_form[:body]}
                    type="textarea"
                    placeholder="Share your thoughts..."
                    class="textarea textarea-bordered w-full"
                    phx-focus="comment_focus"
                  />
                  <button type="submit" class="btn btn-primary">Post Comment</button>
                </.form>
              </div>
            <% else %>
              <div class="alert alert-info mb-8">
                <span>
                  <.link navigate={~p"/auth/signin"} class="link link-primary">Sign in</.link>
                  to comment on this prompt
                </span>
              </div>
            <% end %>

            <div class="space-y-4">
              <%= if @prompt.comments && length(@prompt.comments) > 0 do %>
                <%= for comment <- @prompt.comments do %>
                  <div class="card bg-base-200">
                    <div class="card-body p-4">
                      <div class="flex justify-between items-start">
                        <div>
                          <p class="font-semibold text-base-content">
                            {(comment.user && comment.user.username) || "Anonymous"}
                          </p>
                          <p class="text-xs text-base-content/60">
                            {Calendar.strftime(comment.inserted_at, "%B %d, %Y at %H:%M")}
                          </p>
                        </div>

                        <%= if @current_user && (comment.user_id == @current_user.id or @current_user.is_admin) do %>
                          <button
                            phx-click="delete_comment"
                            phx-value-id={comment.id}
                            class="btn btn-xs btn-ghost text-error"
                          >
                            Delete
                          </button>
                        <% end %>
                      </div>

                      <p class="text-base-content mt-3">{comment.body}</p>
                    </div>
                  </div>
                <% end %>
              <% else %>
                <p class="text-base-content/60 text-center py-8">No comments yet. Be the first!</p>
              <% end %>
            </div>
          </div>
        </div>
    </div>
    """
  end
end
