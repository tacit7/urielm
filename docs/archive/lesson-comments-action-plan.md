# Lesson Comments – Implementation Action Plan

Goal: Add a simple, non-threaded comment system for lessons in the Phoenix app.

---

## 0. Assumptions

- Phoenix 1.7+ with `users` and `lessons` tables already in place.
- Each comment belongs to:
  - a lesson (`lesson_id`)
  - optionally a user (`user_id`, nullable for anonymous comments).
- Server-rendered HTML/HEEx templates (no separate SPA).

---

## 1. Create the database table

### 1.1 Generate migration

```bash
mix ecto.gen.migration create_lesson_comments
```

### 1.2 Define migration

```elixir
def change do
  create table(:lesson_comments) do
    add :body, :text, null: false

    add :lesson_id,
      references(:lessons, on_delete: :delete_all),
      null: false

    add :user_id,
      references(:users, on_delete: :nilify_all)

    timestamps()
  end

  create index(:lesson_comments, [:lesson_id])
  create index(:lesson_comments, [:user_id])
end
```

### 1.3 Run migration

```bash
mix ecto.migrate
```

---

## 2. Define schemas

### 2.1 `LessonComment` schema

Create `lib/your_app/courses/lesson_comment.ex`:

```elixir
defmodule YourApp.Courses.LessonComment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "lesson_comments" do
    field :body, :string

    belongs_to :lesson, YourApp.Courses.Lesson
    belongs_to :user,   YourApp.Accounts.User

    timestamps()
  end

  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:body, :lesson_id, :user_id])
    |> validate_required([:body, :lesson_id])
    |> validate_length(:body, min: 3, max: 2000)
  end
end
```

### 2.2 Wire into `Lesson` schema

In `lib/your_app/courses/lesson.ex`:

```elixir
schema "lessons" do
  # ...existing fields...

  has_many :comments, YourApp.Courses.LessonComment

  timestamps()
end
```

---

## 3. Add context functions

In `lib/your_app/courses.ex`:

```elixir
alias YourApp.Courses.{Lesson, LessonComment}
alias YourApp.Repo
import Ecto.Query

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
```

Optional: add helper to preload comments when loading a lesson.

```elixir
def get_lesson_with_comments!(id) do
  Lesson
  |> Repo.get!(id)
  |> Repo.preload(comments: [:user])
end
```

---

## 4. Update routes

In `lib/your_app_web/router.ex`, under the scope where lessons live:

```elixir
resources "/lessons", LessonController, only: [:show] do
  post "/comments", LessonController, :create_comment
end
```

This defines `POST /lessons/:lesson_id/comments`.

---

## 5. Controller logic

In `lib/your_app_web/controllers/lesson_controller.ex`:

### 5.1 Show action

```elixir
def show(conn, %{"id" => id}) do
  lesson =
    id
    |> Courses.get_lesson_with_comments!()

  changeset = Courses.change_lesson_comment()

  render(conn, :show,
    lesson: lesson,
    comment_changeset: changeset
  )
end
```

(If you do not add `get_lesson_with_comments!/1`, inline the preload here.)

### 5.2 Create comment action

```elixir
def create_comment(conn, %{"lesson_id" => lesson_id, "comment" => params}) do
  user = conn.assigns[:current_user]

  attrs =
    params
    |> Map.put("lesson_id", lesson_id)
    |> Map.put("user_id", user && user.id)

  case Courses.create_lesson_comment(attrs) do
    {:ok, _comment} ->
      conn
      |> put_flash(:info, "Comment added.")
      |> redirect(to: ~p"/lessons/#{lesson_id}")

    {:error, %Ecto.Changeset{} = changeset} ->
      lesson =
        lesson_id
        |> Courses.get_lesson_with_comments!()

      render(conn, :show,
        lesson: lesson,
        comment_changeset: changeset
      )
  end
end
```

If you require login to comment, enforce it before using `current_user` (plug or guard).

---

## 6. Lesson page UI (HEEx + Tailwind/DaisyUI)

In `lib/your_app_web/controllers/lesson_html/show.html.heex`, under the lesson content:

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
        <p class="text-sm whitespace-pre-line">
          <%= comment.body %>
        </p>
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
    action={~p"/lessons/#{@lesson}/comments"}
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
      Post comment
    </button>
  </.form>
</section>
```

---

## 7. Minimal auth & validation

- If comments should require login, add a plug or guard in the controller:

```elixir
plug :require_authenticated_user when action in [:create_comment]
```

- Validation is already enforced via `validate_length/3` and `validate_required/3`.
- Optional: disallow empty-only whitespace comments with a custom validation.

---

## 8. Manual test checklist

1. Run migrations.
2. Visit a lesson page.
3. Verify the Comments section renders.
4. Submit a valid comment:
   - It is persisted.
   - It shows up in the list immediately after redirect.
5. Submit an invalid comment (e.g., empty body):
   - Page re-renders with validation error.
6. Log out (if you support anonymous comments):
   - Submit a comment.
   - Confirm it shows as “Anonymous” and saves with `user_id = NULL`.

---

## 9. Future improvements (backlog)

- Edit and delete own comments.
- Threaded replies (`parent_id` on `lesson_comments`).
- Markdown support with HTML sanitization.
- Notifications for lesson owners when new comments are posted.
- LiveView / JS hooks for real-time updates without full-page reloads.
