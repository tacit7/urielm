# LiveView-Compatible Action Plan Update for Lesson Comments

This document updates the previous action plan so that the comments feature works **inside a LiveView**, not a traditional controller-based template.

The DB layer remains the same; only the UI submission mechanism changes.

---

## 1. What Stays the Same

These pieces do **not** change:

- Migration for `lesson_comments`
- `LessonComment` schema
- `has_many :comments` on `Lesson`
- Context helpers:

```elixir
def list_lesson_comments(%Lesson{id: lesson_id}) do
  LessonComment
  |> where([c], c.lesson_id == ^lesson_id)
  |> order_by(asc: :inserted_at)
  |> preload(:user)
  |> Repo.all()
end

def create_lesson_comment(attrs) do
  %LessonComment{}
  |> LessonComment.changeset(attrs)
  |> Repo.insert()
end

def change_lesson_comment(comment \ %LessonComment{}) do
  LessonComment.changeset(comment, %{})
end

def get_lesson_with_comments!(id) do
  Lesson
  |> Repo.get!(id)
  |> Repo.preload(comments: [:user])
end
```

Only the controller + POST route must be removed and replaced with LiveView logic.

---

## 2. LiveView Routing

Ensure your `router.ex` has something like:

```elixir
live "/lessons/:id", LessonLive.Show, :show
```

Remove any leftover controller route like:

```elixir
post "/lessons/:lesson_id/comments"
```

LiveView will handle submission now.

---

## 3. LiveView Module Implementation

Example `LessonLive.Show`:

```elixir
defmodule YourAppWeb.LessonLive.Show do
  use YourAppWeb, :live_view

  alias YourApp.Courses
  alias YourApp.Courses.LessonComment

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    lesson = Courses.get_lesson_with_comments!(id)

    changeset = Courses.change_lesson_comment(%LessonComment{})

    socket =
      socket
      |> assign(:lesson, lesson)
      |> assign(:comment_changeset, changeset)
      |> assign_new(:current_user, fn -> nil end)

    {:ok, socket}
  end

  @impl true
  def handle_event("save_comment", %{"comment" => params}, socket) do
    lesson = socket.assigns.lesson
    user   = socket.assigns.current_user

    attrs =
      params
      |> Map.put("lesson_id", lesson.id)
      |> Map.put("user_id", user && user.id)

    case Courses.create_lesson_comment(attrs) do
      {:ok, _comment} ->
        lesson = Courses.get_lesson_with_comments!(lesson.id)

        {:noreply,
         socket
         |> put_flash(:info, "Comment added.")
         |> assign(:lesson, lesson)
         |> assign(:comment_changeset, Courses.change_lesson_comment(%LessonComment{}))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :comment_changeset, changeset)}
    end
  end
end
```

---

## 4. LiveView Template (`*.html.heex`)

Replace your comment form with a LiveView event-driven form.

```elixir
<section class="mt-10 space-y-4">
  <h2 class="text-lg font-semibold">Comments</h2>

  <%= if @lesson.comments == [] do %>
    <p class="text-sm text-base-content/60">
      No comments yet. Be the first.
    </p>
  <% end %>

  <ul class="space-y-3">
    <%= for comment <- @lesson.comments do %>
      <li class="card bg-base-200 rounded-xl p-3">
        <p class="text-sm whitespace-pre-line"><%= comment.body %></p>
        <p class="mt-2 text-xs text-base-content/60">
          <%= if comment.user do %>
            <%= comment.user.name || comment.user.email %>
          <% else %>
            Anonymous
          <% end %>
          · <%= Calendar.strftime(comment.inserted_at, "%Y-%m-%d %H:%M") %>
        </p>
      </li>
    <% end %>
  </ul>

  <.form
    for={@comment_changeset}
    as={:comment}
    phx-submit="save_comment"
    class="mt-6 space-y-3"
  >
    <div class="form-control">
      <label class="label">
        <span class="label-text">Add a comment</span>
      </label>

      <textarea
        name="comment[body]"
        class="textarea textarea-bordered w-full"
        rows="3"
      ><%= input_value(@comment_changeset, :body) %></textarea>

      <p class="mt-1 text-xs text-error">
        <%= for {msg, _} <- Keyword.get_values(@comment_changeset.errors, :body) do %>
          <%= msg %>
        <% end %>
      </p>
    </div>

    <button class="btn btn-primary btn-sm">
      Post Comment
    </button>
  </.form>
</section>
```

### Key differences:

- `phx-submit="save_comment"` replaces HTTP POST.
- No `action` attribute on the form.
- LiveView reassigns values and re-renders automatically.
- Validation errors appear without refresh.

---

## 5. Optional: Authentication Guard in LiveView

If comments require login:

```elixir
def handle_event("save_comment", _params, %{assigns: %{current_user: nil}} = socket) do
  {:noreply, put_flash(socket, :error, "You must be logged in to comment.")}
end
```

Otherwise, anonymous commenters get `user_id = nil`.

---

## 6. Workflow Summary

1. Load lesson and comments in `mount/3`.
2. Render comment list + form.
3. User submits form with `phx-submit`.
4. LiveView receives `"save_comment"` event.
5. Insert comment via context.
6. On success:
   - reload comments
   - clear textarea
   - show flash
7. LiveView updates the page instantly.

---

## 7. Future Enhancements

- LiveView `stream` for comments (more efficient than reload)
- Edit/delete own comments
- Threaded comments via `parent_id`
- Markdown with sanitization
- Real-time updates via PubSub

---

This updated plan brings the comment system fully inline with **Phoenix LiveView**, without relying on traditional controllers or HTTP forms.
