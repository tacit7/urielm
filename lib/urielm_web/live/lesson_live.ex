defmodule UrielmWeb.LessonLive do
  use UrielmWeb, :live_view
  alias Urielm.Engagement
  alias Urielm.Learning
  alias Urielm.Learning.LessonComment
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

    course_slug = child_params["course_slug"]
    lesson_slug = child_params["lesson_slug"]

    if connected?(socket) do
      case Learning.get_course_by_slug(course_slug) do
        nil ->
          {:ok,
           socket
           |> put_flash(:error, "Course not found")
           |> push_navigate(to: ~p"/")}

        course ->
          case Learning.get_lesson_with_comments(course.id, lesson_slug) do
            nil ->
              {:ok,
               socket
               |> put_flash(:error, "Lesson not found")
               |> push_navigate(to: ~p"/")}

            lesson ->
              lessons = Learning.list_lessons(course.id)
              changeset = Learning.change_lesson_comment(%LessonComment{})
              nav_items = build_nav_items(lesson, course)
              current_index = Enum.find_index(lessons, &(&1.id == lesson.id))

              prev_lesson =
                if current_index && current_index > 0,
                  do: Enum.at(lessons, current_index - 1),
                  else: nil

              next_lesson = if current_index, do: Enum.at(lessons, current_index + 1), else: nil

              %{current_user: user} = socket.assigns

              {upvotes, downvotes, _score} =
                Engagement.get_vote_counts("lesson", to_string(lesson.id))

              user_vote =
                if user,
                  do: Engagement.get_vote(user.id, "lesson", to_string(lesson.id)),
                  else: nil

              {:ok,
               socket
               |> assign(:course, course)
               |> assign(:lesson, lesson)
               |> assign(:lessons, lessons)
               |> assign(:comment_changeset, changeset)
               |> assign(:comment_form, Phoenix.Component.to_form(changeset, as: :comment))
               |> assign(:current_page, "courses")
               |> assign(:page_title, lesson.title)
               |> assign(:dock_tab, "home")
               |> assign(:active_section, "home")
               |> assign(:nav_items, nav_items)
               |> assign(:upvotes, upvotes)
               |> assign(:downvotes, downvotes)
               |> assign(:user_vote, user_vote && user_vote.value)
               |> assign(:prev_lesson, prev_lesson)
               |> assign(:next_lesson, next_lesson)}
          end
      end
    else
      {:ok,
       socket
       |> assign(:course, nil)
       |> assign(:lesson, nil)
       |> assign(:lessons, [])
       |> assign(:comment_changeset, nil)
       |> assign(:comment_form, nil)
       |> assign(:current_page, "courses")
       |> assign(:dock_tab, "home")
       |> assign(:active_section, "home")
       |> assign(:nav_items, [])
       |> assign(:upvotes, 0)
       |> assign(:downvotes, 0)
       |> assign(:user_vote, nil)
       |> assign(:prev_lesson, nil)
       |> assign(:next_lesson, nil)}
    end
  end

  defp build_nav_items(lesson, _course) do
    items = [%{key: "home", label: "Overview"}]

    items =
      if lesson.notes_md && lesson.notes_md != "",
        do: items ++ [%{key: "notes", label: "Notes"}],
        else: items

    items =
      if lesson.resources_md && lesson.resources_md != "",
        do: items ++ [%{key: "resources", label: "Resources"}],
        else: items

    items =
      if lesson.timestamps_md && lesson.timestamps_md != "",
        do: items ++ [%{key: "timestamps", label: "Timestamps"}],
        else: items

    # Always show comments
    items ++ [%{key: "comments", label: "Comments", count: length(lesson.comments || [])}]
  end

  # Visibility helper for mobile dock + desktop tabs
  # Mobile: show if dock_tab matches
  # Desktop: show if active_section matches
  defp section_visibility(dock_tab, active_section, section_key) do
    mobile_matches = dock_tab == section_key
    desktop_matches = active_section == section_key

    case {mobile_matches, desktop_matches} do
      {true, true} -> ""
      {true, false} -> "lg:hidden"
      {false, true} -> "hidden lg:block"
      {false, false} -> "hidden"
    end
  end

  @impl true
  def handle_event("set_dock_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :dock_tab, tab)}
  end

  @impl true
  def handle_event("tab_change", %{"key" => key}, socket) do
    {:noreply, assign(socket, :active_section, key)}
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
  def handle_event("save_comment", %{"comment" => params0}, socket) do
    user = socket.assigns[:current_user]

    if !user do
      {:noreply,
       socket
       |> put_flash(:info, "Sign in to comment on this lesson.")}
    else
      lesson = socket.assigns.lesson

      attrs =
        Params.normalize(params0)
        |> Map.put("lesson_id", lesson.id)
        |> Map.put("user_id", user.id)

      case Learning.create_lesson_comment(attrs) do
        {:ok, _comment} ->
          lesson = Learning.get_lesson_with_comments(socket.assigns.course.id, lesson.slug)

          {:noreply,
           socket
           |> put_flash(:info, "Comment added.")
           |> assign(:lesson, lesson)
           |> assign(:nav_items, build_nav_items(lesson, socket.assigns.course))
           |> assign(:comment_changeset, Learning.change_lesson_comment(%LessonComment{}))
           |> assign(
             :comment_form,
             Phoenix.Component.to_form(Learning.change_lesson_comment(%LessonComment{}),
               as: :comment
             )
           )}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply,
           socket
           |> assign(:comment_changeset, changeset)
           |> assign(:comment_form, Phoenix.Component.to_form(changeset, as: :comment))}
      end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @lesson do %>
      <div id="lesson-viewer" class="drawer drawer-end min-h-screen bg-base-100">
        <input id="lesson-drawer" type="checkbox" class="drawer-toggle" />

        <div class="drawer-content min-w-0">
          <div class="mx-auto max-w-7xl px-5 pb-28 pt-6 sm:px-7 lg:px-10 lg:pb-16 lg:pt-10">
            <nav class="mb-5 flex items-center justify-between gap-4" aria-label="Lesson breadcrumb">
              <.link
                navigate={~p"/courses/#{@course.slug}"}
                class="inline-flex min-w-0 items-center gap-2 font-mono text-xs uppercase tracking-widest text-base-content/50 transition-colors hover:text-primary"
              >
                <.um_icon name="hero-arrow-left" class="size-3.5 flex-none" />
                <span class="truncate">{@course.title}</span>
              </.link>

              <label
                for="lesson-drawer"
                class="btn btn-ghost btn-sm gap-2 lg:hidden"
                title="Open course outline"
              >
                <.um_icon name="hero-queue-list" class="size-4" /> Outline
              </label>
            </nav>

            <div class="grid min-w-0 gap-7 lg:grid-cols-[minmax(0,1fr)_20rem] xl:gap-9">
              <main class="min-w-0">
                <.learning_media_player
                  id="lesson-player"
                  label="Lesson video"
                  class="-mx-5 aspect-video sm:mx-0"
                >
                  <.svelte
                    name="YouTubePlayer"
                    props={%{videoId: @lesson.youtube_video_id, controls: true}}
                    socket={@socket}
                    class="h-full w-full"
                    ssr={false}
                  />
                </.learning_media_player>

                <header
                  id="lesson-header"
                  class="flex flex-col gap-5 border-b border-base-content/10 py-6 sm:flex-row sm:items-start sm:justify-between sm:py-8"
                >
                  <div class="min-w-0 max-w-3xl">
                    <p class="ui-eyebrow mb-2">
                      Lesson {String.pad_leading(to_string(@lesson.lesson_number), 2, "0")} of {String.pad_leading(
                        to_string(length(@lessons)),
                        2,
                        "0"
                      )}
                    </p>
                    <h1 class="text-3xl font-black leading-tight tracking-tight text-base-content sm:text-4xl">
                      {@lesson.title}
                    </h1>
                  </div>

                  <div class="w-fit flex-none rounded-full border border-base-content/10 bg-base-200/65 px-2 py-1">
                    <.svelte
                      name="VoteButtons"
                      props={
                        %{
                          target_type: "lesson",
                          target_id: to_string(@lesson.id),
                          upvotes: @upvotes,
                          downvotes: @downvotes,
                          user_vote: @user_vote,
                          layout: "horizontal",
                          size: "sm"
                        }
                      }
                      socket={@socket}
                      ssr={false}
                    />
                  </div>
                </header>

                <.learning_media_tabs
                  id="lesson-section-nav"
                  label="Lesson details"
                  items={@nav_items}
                  active_key={@active_section}
                  item_id_prefix="lesson-tab"
                  class="hidden pt-1 lg:flex"
                />

                <div id="lesson-content" class="pt-6 sm:pt-8">
                  <section
                    id="lesson-overview"
                    class={[
                      "ui-card space-y-6 p-5 sm:p-7",
                      section_visibility(@dock_tab, @active_section, "home")
                    ]}
                  >
                    <div class="flex items-center gap-3">
                      <div class="flex size-10 flex-none items-center justify-center rounded-full bg-primary/10 text-primary">
                        <.um_icon name="hero-academic-cap" class="size-5" />
                      </div>
                      <div class="min-w-0">
                        <.link
                          navigate={~p"/courses/#{@course.slug}"}
                          class="font-black text-base-content transition-colors hover:text-primary"
                        >
                          {@course.title}
                        </.link>
                        <p class="text-xs text-base-content/50">
                          Lesson {@lesson.lesson_number} · {length(@lessons)} total
                        </p>
                      </div>
                    </div>

                    <div :if={@course.description} class="border-t border-base-content/10 pt-5">
                      <h2 class="mb-2 text-lg font-black text-base-content">About this course</h2>
                      <p class="max-w-3xl text-sm leading-relaxed text-base-content/65 sm:text-base">
                        {@course.description}
                      </p>
                    </div>
                  </section>

                  <section
                    id="lesson-notes"
                    class={[
                      "ui-card p-5 sm:p-7",
                      section_visibility(@dock_tab, @active_section, "notes")
                    ]}
                  >
                    <p class="ui-eyebrow mb-2">Reference</p>
                    <h2 class="mb-5 text-2xl font-black tracking-tight text-base-content">
                      Lesson notes
                    </h2>
                    <div :if={@lesson.notes_md} class="prose prose-sm max-w-none sm:prose-base">
                      <.svelte
                        name="MarkdownRenderer"
                        props={%{content: @lesson.notes_md}}
                        socket={@socket}
                        ssr={false}
                      />
                    </div>
                    <.empty_state
                      :if={!@lesson.notes_md}
                      id="lesson-notes-empty"
                      title="No lesson notes"
                      description="No notes are available for this lesson."
                      icon="hero-document-text"
                      compact
                    />
                  </section>

                  <section
                    id="lesson-resources"
                    class={[
                      "ui-card p-5 sm:p-7",
                      section_visibility(@dock_tab, @active_section, "resources")
                    ]}
                  >
                    <p class="ui-eyebrow mb-2">Continue learning</p>
                    <h2 class="mb-5 text-2xl font-black tracking-tight text-base-content">
                      Resources
                    </h2>
                    <div :if={@lesson.resources_md} class="prose prose-sm max-w-none sm:prose-base">
                      <.svelte
                        name="MarkdownRenderer"
                        props={%{content: @lesson.resources_md}}
                        socket={@socket}
                        ssr={false}
                      />
                    </div>
                    <.empty_state
                      :if={!@lesson.resources_md}
                      id="lesson-resources-empty"
                      title="No additional resources"
                      description="No additional resources are available."
                      icon="hero-link"
                      compact
                    />
                  </section>

                  <section
                    id="lesson-timestamps"
                    class={[
                      "ui-card p-5 sm:p-7",
                      section_visibility(@dock_tab, @active_section, "timestamps")
                    ]}
                  >
                    <p class="ui-eyebrow mb-2">Video guide</p>
                    <h2 class="mb-5 text-2xl font-black tracking-tight text-base-content">
                      Timestamps
                    </h2>
                    <div :if={@lesson.timestamps_md} class="prose prose-sm max-w-none sm:prose-base">
                      <.svelte
                        name="MarkdownRenderer"
                        props={%{content: @lesson.timestamps_md}}
                        socket={@socket}
                        ssr={false}
                      />
                    </div>
                    <.empty_state
                      :if={!@lesson.timestamps_md}
                      id="lesson-timestamps-empty"
                      title="No timestamps"
                      description="No timestamps are available for this video."
                      icon="hero-clock"
                      compact
                    />
                  </section>

                  <section
                    id="lesson-comments"
                    class={[
                      "ui-card p-5 sm:p-7",
                      section_visibility(@dock_tab, @active_section, "comments")
                    ]}
                  >
                    <div class="mb-6 flex items-end justify-between gap-4">
                      <div>
                        <p class="ui-eyebrow mb-2">Discussion</p>
                        <h2 class="text-2xl font-black tracking-tight text-base-content">Comments</h2>
                      </div>
                      <span class="badge badge-outline h-auto px-3 py-2 font-mono text-xs text-base-content/60">
                        {length(@lesson.comments)}
                      </span>
                    </div>

                    <.empty_state
                      :if={@lesson.comments == []}
                      id="lesson-comments-empty"
                      title="No comments yet"
                      description="Start the conversation with a useful question or observation."
                      icon="hero-chat-bubble-left-right"
                      compact
                    />

                    <ul id="lesson-comment-list" class="divide-y divide-base-content/10">
                      <li
                        :for={comment <- @lesson.comments}
                        id={"lesson-comment-#{comment.id}"}
                        class="py-4 first:pt-0 last:pb-0"
                      >
                        <div class="flex flex-wrap items-baseline gap-x-2 gap-y-1">
                          <p class="font-semibold text-base-content">
                            {if comment.user,
                              do: comment.user.name || comment.user.email,
                              else: "Anonymous"}
                          </p>
                          <time
                            datetime={NaiveDateTime.to_iso8601(comment.inserted_at)}
                            class="text-xs text-base-content/50"
                          >
                            {Calendar.strftime(comment.inserted_at, "%b %d, %Y at %H:%M")}
                          </time>
                        </div>
                        <p class="mt-2 whitespace-pre-line text-sm leading-6 text-base-content/80 sm:text-base">
                          {comment.body}
                        </p>
                      </li>
                    </ul>

                    <%= if @current_user do %>
                      <.form
                        for={@comment_form}
                        id="lesson-comment-form"
                        phx-submit="save_comment"
                        class="mt-6 border-t border-base-content/10 pt-6"
                      >
                        <.input
                          field={@comment_form[:body]}
                          type="textarea"
                          label="Add a comment"
                          placeholder="Share a useful question or observation..."
                          rows="4"
                        />
                        <div class="mt-3 flex justify-end">
                          <button
                            id="lesson-comment-submit"
                            type="submit"
                            class="btn btn-primary btn-sm"
                          >
                            Post comment
                          </button>
                        </div>
                      </.form>
                    <% else %>
                      <div id="lesson-sign-in-to-comment" class="alert alert-info mt-6">
                        <.um_icon name="hero-information-circle" class="size-5 shrink-0" />
                        <span>
                          <.link navigate={~p"/signin"} class="link link-primary font-semibold">
                            Sign in
                          </.link>
                          to join the lesson discussion.
                        </span>
                      </div>
                    <% end %>
                  </section>
                </div>

                <nav
                  id="lesson-progress"
                  class="mt-5 grid gap-3 sm:grid-cols-2"
                  aria-label="Lesson progression"
                >
                  <.link
                    :if={@prev_lesson}
                    id="previous-lesson-link"
                    navigate={~p"/courses/#{@course.slug}/lessons/#{@prev_lesson.slug}"}
                    class="ui-card ui-card-interactive group p-4 sm:p-5"
                  >
                    <span class="mb-2 flex items-center gap-1.5 font-mono text-[0.68rem] uppercase tracking-widest text-base-content/45">
                      <.um_icon name="hero-arrow-left" class="size-3.5" /> Previous lesson
                    </span>
                    <strong class="line-clamp-2 text-base-content transition-colors group-hover:text-primary">
                      {@prev_lesson.title}
                    </strong>
                  </.link>

                  <.link
                    :if={@next_lesson}
                    id="next-lesson-link"
                    navigate={~p"/courses/#{@course.slug}/lessons/#{@next_lesson.slug}"}
                    class="ui-card ui-card-interactive group p-4 text-left sm:p-5 sm:text-right"
                  >
                    <span class="mb-2 flex items-center gap-1.5 font-mono text-[0.68rem] uppercase tracking-widest text-base-content/45 sm:justify-end">
                      Next lesson <.um_icon name="hero-arrow-right" class="size-3.5" />
                    </span>
                    <strong class="line-clamp-2 text-base-content transition-colors group-hover:text-primary">
                      {@next_lesson.title}
                    </strong>
                  </.link>
                </nav>
              </main>

              <div class="hidden lg:block">
                <.course_outline
                  id="course-outline"
                  course={@course}
                  lesson={@lesson}
                  lessons={@lessons}
                />
              </div>
            </div>
          </div>

          <div
            id="lesson-mobile-dock"
            data-navigation="lesson-dock"
            aria-label="Lesson sections"
            class="dock fixed inset-x-0 bottom-[calc(3.5rem+env(safe-area-inset-bottom))] z-20 border-t border-base-content/10 bg-base-200 lg:hidden"
          >
            <.dock_button
              id="lesson-mobile-overview"
              tab="home"
              active={@dock_tab}
              icon="hero-home"
              label="Overview"
            />
            <.dock_button
              :if={@lesson.notes_md}
              id="lesson-mobile-notes"
              tab="notes"
              active={@dock_tab}
              icon="hero-document-text"
              label="Notes"
            />
            <.dock_button
              :if={@lesson.resources_md}
              id="lesson-mobile-resources"
              tab="resources"
              active={@dock_tab}
              icon="hero-link"
              label="Resources"
            />
            <.dock_button
              :if={@lesson.timestamps_md}
              id="lesson-mobile-timestamps"
              tab="timestamps"
              active={@dock_tab}
              icon="hero-clock"
              label="Times"
            />
            <.dock_button
              id="lesson-mobile-comments"
              tab="comments"
              active={@dock_tab}
              icon="hero-chat-bubble-left-right"
              label="Comments"
            />
          </div>
        </div>

        <div class="drawer-side z-40 lg:hidden">
          <label for="lesson-drawer" class="drawer-overlay" aria-label="Close course outline"></label>
          <.course_outline
            id="course-outline-mobile"
            course={@course}
            lesson={@lesson}
            lessons={@lessons}
            mobile
          />
        </div>
      </div>
    <% end %>
    """
  end

  attr :id, :string, required: true
  attr :course, :map, required: true
  attr :lesson, :map, required: true
  attr :lessons, :list, required: true
  attr :mobile, :boolean, default: false

  defp course_outline(assigns) do
    ~H"""
    <aside
      id={@id}
      class={[
        "overflow-hidden border border-base-content/10 bg-base-200/70",
        if(@mobile,
          do: "flex h-full w-80 flex-col rounded-none",
          else: "sticky top-24 rounded-2xl"
        )
      ]}
    >
      <header class="flex items-start justify-between gap-4 border-b border-base-content/10 p-5">
        <div class="min-w-0">
          <p class="ui-eyebrow mb-1">Course outline</p>
          <h2 class="truncate font-black text-base-content">{@course.title}</h2>
          <p class="mt-1 text-xs text-base-content/50">
            {length(@lessons)} {if length(@lessons) == 1, do: "lesson", else: "lessons"}
          </p>
        </div>
        <label
          :if={@mobile}
          for="lesson-drawer"
          class="btn btn-ghost btn-sm btn-circle"
          title="Close course outline"
        >
          <.um_icon name="hero-x-mark" class="size-4" />
        </label>
      </header>

      <div class={["grid gap-1 p-2", @mobile && "flex-1 overflow-y-auto"]}>
        <.link
          :for={course_lesson <- @lessons}
          id={
            if(@mobile,
              do: "outline-mobile-lesson-#{course_lesson.id}",
              else: "outline-lesson-#{course_lesson.id}"
            )
          }
          aria-current={if(course_lesson.id == @lesson.id, do: "page", else: nil)}
          navigate={~p"/courses/#{@course.slug}/lessons/#{course_lesson.slug}"}
          class={[
            "group flex gap-3 rounded-xl border p-2.5 transition duration-200",
            if(course_lesson.id == @lesson.id,
              do: "border-primary/30 bg-primary/10",
              else: "border-transparent hover:border-base-content/10 hover:bg-base-300/65"
            )
          ]}
        >
          <div class="relative aspect-video w-24 flex-none overflow-hidden rounded-lg bg-[#10121f]">
            <img
              :if={course_lesson.youtube_video_id}
              src={"https://i.ytimg.com/vi/#{course_lesson.youtube_video_id}/mqdefault.jpg"}
              alt=""
              class="h-full w-full object-cover opacity-80 transition duration-300 group-hover:opacity-100"
            />
            <div
              :if={course_lesson.id == @lesson.id}
              class="absolute inset-0 flex items-center justify-center bg-[#10121f]/45 text-white"
            >
              <span class="flex size-7 items-center justify-center rounded-full bg-primary text-primary-content">
                <.um_icon name="hero-play" class="ml-0.5 size-3.5" />
              </span>
            </div>
            <span class="absolute left-1.5 top-1.5 rounded bg-[#10121f]/85 px-1.5 py-0.5 font-mono text-[0.62rem] text-[#f2f4ff]">
              {String.pad_leading(to_string(course_lesson.lesson_number), 2, "0")}
            </span>
          </div>

          <div class="min-w-0 py-0.5">
            <p class="mb-1 font-mono text-[0.62rem] uppercase tracking-widest text-base-content/45">
              {if course_lesson.id == @lesson.id, do: "Now playing", else: "Lesson"}
            </p>
            <h3 class={[
              "line-clamp-2 text-sm font-bold leading-snug transition-colors",
              if(course_lesson.id == @lesson.id,
                do: "text-primary",
                else: "text-base-content group-hover:text-primary"
              )
            ]}>
              {course_lesson.title}
            </h3>
          </div>
        </.link>
      </div>

      <footer class="border-t border-base-content/10 p-3">
        <.link
          navigate={~p"/courses/#{@course.slug}"}
          class="btn btn-ghost btn-sm w-full justify-start gap-2"
        >
          <.um_icon name="hero-squares-2x2" class="size-4" /> View course
        </.link>
      </footer>
    </aside>
    """
  end

  attr :id, :string, required: true
  attr :tab, :string, required: true
  attr :active, :string, required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true

  defp dock_button(assigns) do
    ~H"""
    <button
      id={@id}
      type="button"
      phx-click="set_dock_tab"
      phx-value-tab={@tab}
      class={["dock-item", @active == @tab && "dock-active"]}
      aria-label={"#{@label} tab"}
    >
      <.um_icon name={@icon} class="size-5" />
      <span class="dock-label text-[0.68rem]">{@label}</span>
    </button>
    """
  end
end
