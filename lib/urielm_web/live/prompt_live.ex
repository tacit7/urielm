defmodule UrielmWeb.PromptLive do
  use UrielmWeb, :live_view
  use LiveSvelte.Components

  alias Urielm.Content
  alias Urielm.Content.Comment
  alias Urielm.Engagement
  alias Urielm.Params
  alias UrielmWeb.LiveHelpers

  @impl true
  def mount(params, session, socket) do
    # Handle both direct mount and child mount via live_render
    child_params =
      case params do
        :not_mounted_at_router -> session["child_params"] || %{}
        params -> params
      end

    id = child_params["id"]

    prompt_id =
      case Integer.parse(id) do
        {n, ""} -> n
        _ -> nil
      end

    case prompt_id do
      nil ->
        {:ok, socket |> put_flash(:error, "Invalid prompt") |> redirect(to: ~p"/prompts")}

      prompt_id ->
        if connected?(socket) do
          case Content.get_prompt_with_comments(prompt_id) do
            nil ->
              {:ok, socket |> put_flash(:error, "Prompt not found") |> redirect(to: ~p"/prompts")}

            prompt ->
              %{current_user: user} = socket.assigns
              target_id = to_string(prompt.id)
              {upvotes, downvotes, _score} = Engagement.get_vote_counts("prompt", target_id)

              user_vote =
                if user, do: Engagement.get_vote(user.id, "prompt", target_id), else: nil

              user_saved = if user, do: Content.user_saved_prompt?(user.id, prompt.id), else: nil

              {:ok,
               socket
               |> assign(:page_title, prompt.title)
               |> assign(:prompt, prompt)
               |> assign(:comment_form, to_form(Content.change_comment(%Comment{})))
               |> assign(:upvotes, upvotes)
               |> assign(:downvotes, downvotes)
               |> assign(:user_vote, user_vote && user_vote.value)
               |> assign(:user_saved, user_saved)}
          end
        else
          {:ok,
           socket
           |> assign(:prompt, nil)
           |> assign(:comment_form, nil)
           |> assign(:upvotes, 0)
           |> assign(:downvotes, 0)
           |> assign(:user_vote, nil)
           |> assign(:user_saved, nil)}
        end
    end
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
            case Content.get_prompt_with_comments(prompt.id) do
              nil ->
                {:noreply,
                 socket |> put_flash(:error, "Prompt not found") |> redirect(to: ~p"/prompts")}

              updated_prompt ->
                {:noreply,
                 socket
                 |> assign(:prompt, updated_prompt)
                 |> assign(:comment_form, to_form(Content.change_comment(%Comment{})))
                 |> put_flash(:info, "Comment posted")}
            end

          {:error, changeset} ->
            {:noreply, assign(socket, :comment_form, to_form(changeset))}
        end
    end
  end

  @impl true
  def handle_event("delete_comment", %{"id" => comment_id}, socket) do
    %{current_user: user, prompt: prompt} = socket.assigns

    parsed_id =
      case Integer.parse(comment_id) do
        {n, ""} -> n
        _ -> nil
      end

    case parsed_id do
      nil ->
        {:noreply, put_flash(socket, :error, "Invalid comment ID")}

      parsed_id ->
        case Content.get_comment(parsed_id) do
          nil ->
            {:noreply, put_flash(socket, :error, "Comment not found")}

          comment ->
            if user && (comment.user_id == user.id or user.is_admin) do
              case Content.delete_comment(comment) do
                {:ok, _} ->
                  case Content.get_prompt_with_comments(prompt.id) do
                    nil ->
                      {:noreply,
                       socket
                       |> put_flash(:error, "Prompt not found")
                       |> redirect(to: ~p"/prompts")}

                    updated_prompt ->
                      {:noreply, assign(socket, :prompt, updated_prompt)}
                  end

                {:error, _} ->
                  {:noreply, put_flash(socket, :error, "Failed to delete comment")}
              end
            else
              {:noreply, put_flash(socket, :error, "Not authorized")}
            end
        end
    end
  end

  @impl true
  def handle_event(
        "vote",
        %{"target_type" => target_type, "target_id" => id, "value" => value},
        socket
      ) do
    LiveHelpers.handle_vote(target_type, id, value, socket)
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

  defp handle_toggle_save(user, prompt_id, socket) do
    case Content.toggle_save(user.id, prompt_id) do
      {:ok, _} ->
        case Content.get_prompt_with_comments(prompt_id) do
          nil ->
            {:noreply,
             socket |> put_flash(:error, "Prompt not found") |> redirect(to: ~p"/prompts")}

          updated_prompt ->
            user_saved = Content.user_saved_prompt?(user.id, prompt_id)

            {:noreply,
             socket
             |> assign(:prompt, updated_prompt)
             |> assign(:user_saved, user_saved)}
        end

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to save prompt")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="prompt-detail-page" class="ui-page-shell max-w-5xl">
      <%= if @prompt do %>
        <.link
          id="prompt-back-link"
          navigate={~p"/prompts?#{%{category: @prompt.category}}"}
          class="btn btn-ghost btn-sm -ml-2 mb-5 gap-2 text-base-content/55 hover:text-primary"
        >
          <.um_icon name="hero-arrow-left" class="size-4" /> All prompts
        </.link>

        <header id="prompt-detail-header" class="ui-page-header">
          <p class="ui-eyebrow">Prompt library</p>
          <h1 class="ui-section-title max-w-4xl">{@prompt.title}</h1>

          <div class="mt-4 flex flex-wrap items-center gap-3 text-sm text-base-content/55">
            <span class="badge badge-secondary">{@prompt.category}</span>
            <span>{Calendar.strftime(@prompt.inserted_at, "%B %d, %Y")}</span>
          </div>

          <div
            :if={@prompt.tag_records && @prompt.tag_records != []}
            id="prompt-detail-tags"
            class="mt-4 flex flex-wrap gap-2"
          >
            <span :for={tag <- @prompt.tag_records} class="badge badge-outline">{tag.name}</span>
          </div>
        </header>

        <section :if={@prompt.prompt} id="prompt-content-panel" class="ui-card h-auto p-5 sm:p-7">
          <div class="prose max-w-none text-base-content/80 prose-headings:text-base-content prose-a:text-primary">
            <.svelte
              name="MarkdownRenderer"
              props={%{content: @prompt.prompt}}
              socket={@socket}
              ssr={false}
            />
          </div>

          <div class="mt-6 flex items-center justify-between gap-3 border-t border-base-300/60 pt-4">
            <.svelte
              name="PromptActions"
              props={
                %{
                  upvotes: @upvotes,
                  downvotes: @downvotes,
                  savesCount: @prompt.saves_count,
                  userVote: @user_vote,
                  userSaved: @user_saved,
                  promptId: to_string(@prompt.id)
                }
              }
              socket={@socket}
            />
            <button
              id="copy-prompt-btn"
              type="button"
              phx-hook="CopyToClipboard"
              data-text={@prompt.prompt}
              class="btn btn-ghost btn-sm btn-square"
              title="Copy prompt"
              aria-label="Copy prompt"
            >
              <.um_icon name="hero-clipboard-document" class="size-5" />
            </button>
          </div>
        </section>

        <section id="prompt-comments-section" class="mt-10 max-w-3xl">
          <div class="mb-5 flex items-center justify-between gap-4">
            <h2 class="text-xl font-black text-base-content">Comments</h2>
            <span class="badge badge-ghost font-mono text-xs">
              {@prompt.comments_count}
            </span>
          </div>

          <%= if @current_user do %>
            <.form
              for={@comment_form}
              id="prompt-comment-form"
              phx-submit="save_comment"
              class="ui-card ui-card-compact mb-6 h-auto space-y-4 p-4 sm:p-5"
            >
              <.input
                field={@comment_form[:body]}
                id="prompt-comment-body"
                type="textarea"
                label="Your comment"
                placeholder="Share a useful thought"
                required
                class="textarea textarea-bordered min-h-28 w-full resize-y rounded-lg bg-base-100"
                phx-focus="comment_focus"
              />
              <div class="flex justify-end">
                <button id="prompt-comment-submit" type="submit" class="btn btn-primary btn-sm">
                  Post comment
                </button>
              </div>
            </.form>
          <% else %>
            <div id="prompt-sign-in-to-comment" class="alert alert-info mb-6">
              <.um_icon name="hero-information-circle" class="size-5 shrink-0" />
              <span>
                <.link navigate={~p"/signin"} class="link link-primary font-semibold">Sign in</.link>
                to comment on this prompt.
              </span>
            </div>
          <% end %>

          <div id="prompt-comment-list" class="space-y-3">
            <%= if @prompt.comments && @prompt.comments != [] do %>
              <article
                :for={comment <- @prompt.comments}
                id={"prompt-comment-#{comment.id}"}
                class="card ui-card ui-card-compact h-auto"
              >
                <div class="card-body p-4 sm:p-5">
                  <div class="flex items-start justify-between gap-4">
                    <div class="min-w-0">
                      <p class="truncate font-semibold text-base-content">
                        {(comment.user && comment.user.username) || "Anonymous"}
                      </p>
                      <p class="text-xs text-base-content/55">
                        {Calendar.strftime(comment.inserted_at, "%B %d, %Y at %H:%M")}
                      </p>
                    </div>

                    <button
                      :if={
                        @current_user &&
                          (comment.user_id == @current_user.id or @current_user.is_admin)
                      }
                      id={"delete-prompt-comment-#{comment.id}"}
                      type="button"
                      phx-click="delete_comment"
                      phx-value-id={comment.id}
                      class="btn btn-ghost btn-xs text-error"
                    >
                      Delete
                    </button>
                  </div>

                  <p class="mt-3 leading-7 text-base-content/80">{comment.body}</p>
                </div>
              </article>
            <% else %>
              <.empty_state
                id="prompt-comments-empty"
                title="No comments yet"
                description="Start the discussion with a useful observation or question."
                icon="hero-chat-bubble-left-right"
                compact
              />
            <% end %>
          </div>
        </section>
      <% end %>
    </div>
    """
  end
end
