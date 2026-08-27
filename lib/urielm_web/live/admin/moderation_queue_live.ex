defmodule UrielmWeb.Admin.ModerationQueueLive do
  use UrielmWeb, :live_view

  alias Urielm.Forum
  alias UrielmWeb.LiveHelpers

  @page_size 20
  @statuses ~w(pending resolved reviewed dismissed all)

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> stream_configure(:reports, dom_id: &"report-card-#{&1.id}")
      |> assign(:page_title, "Moderation Reports")
      |> assign(:statuses, @statuses)
      |> assign(:active_status, "pending")
      |> assign(:search, "")
      |> assign(:filter_form, to_form(%{"search" => ""}, as: :filters))
      |> assign(:page, 0)
      |> load_reports(reset: true)

    {:ok, socket}
  end

  @impl true
  def handle_event("select_status", %{"status" => status}, socket) when status in @statuses do
    {:noreply,
     socket
     |> assign(:active_status, status)
     |> assign(:page, 0)
     |> load_reports(reset: true)}
  end

  def handle_event("filter_reports", %{"filters" => %{"search" => search}}, socket) do
    search = String.trim(search)

    {:noreply,
     socket
     |> assign(:search, search)
     |> assign(:filter_form, to_form(%{"search" => search}, as: :filters))
     |> assign(:page, 0)
     |> load_reports(reset: true)}
  end

  @impl true
  def handle_event("load_more", _params, %{assigns: %{has_more: false}} = socket),
    do: {:noreply, socket}

  def handle_event("load_more", _params, socket) do
    next_page = socket.assigns.page + 1
    reports = fetch_reports(socket, next_page)

    {:noreply,
     socket
     |> assign(:page, next_page)
     |> assign(:has_more, length(reports) == @page_size)
     |> stream(:reports, serialize_reports(reports))}
  end

  @impl true
  def handle_event("approve", %{"report_id" => report_id}, socket) do
    review_report(socket, report_id, "reviewed", "Approved", "Report approved")
  end

  def handle_event("resolve", %{"report_id" => report_id}, socket) do
    review_report(socket, report_id, "resolved", nil, "Report resolved")
  end

  def handle_event("dismiss", %{"report_id" => report_id}, socket) do
    review_report(socket, report_id, "dismissed", nil, "Report dismissed")
  end

  def handle_event(
        "add_notes",
        %{"report_id" => report_id, "moderation_note" => %{"notes" => notes}},
        socket
      ) do
    report = Forum.get_report!(report_id)

    case Forum.update_report_notes(report, notes) do
      {:ok, _report} ->
        {:noreply,
         socket
         |> load_reports(reset: true)
         |> put_flash(:info, "Moderation note saved")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "We couldn't save that note. Please try again.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_user={@current_user}
      current_page="admin"
      socket={@socket}
      unread_notification_count={@unread_notification_count}
    >
      <div class="min-h-screen bg-base-100">
        <div class="container mx-auto max-w-6xl px-4 py-8 sm:py-10">
          <header class="mb-7 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
            <div>
              <h1 class="text-3xl font-bold tracking-[-0.025em] text-base-content">
                Moderation reports
              </h1>
              <p class="mt-2 max-w-2xl text-sm leading-6 text-base-content/65 sm:text-base">
                Review new reports and revisit past decisions without losing their context.
              </p>
            </div>
            <nav class="hidden items-center gap-1 sm:flex" aria-label="Admin pages">
              <.link navigate="/admin/users" class="btn btn-ghost btn-sm">Users</.link>
              <.link navigate="/admin/trust-levels" class="btn btn-ghost btn-sm">
                Trust levels
              </.link>
            </nav>
          </header>

          <section
            id="moderation-report-toolbar"
            class="rounded-2xl border border-base-300 bg-base-200 p-2"
            aria-label="Report filters"
          >
            <div class="flex flex-col gap-2 lg:flex-row lg:items-center lg:justify-between">
              <div
                class="tabs tabs-box min-w-0 flex-nowrap justify-start overflow-x-auto bg-transparent p-0"
                role="tablist"
                aria-label="Report status"
              >
                <%= for status <- @statuses do %>
                  <button
                    id={"report-filter-#{status}"}
                    type="button"
                    role="tab"
                    aria-selected={to_string(@active_status == status)}
                    phx-click="select_status"
                    phx-value-status={status}
                    class={[
                      "tab min-h-11 shrink-0 rounded-xl px-3 text-sm font-bold transition-colors duration-150 focus-visible:outline-2 focus-visible:outline-offset-[-2px] focus-visible:outline-primary",
                      @active_status == status && "tab-active bg-primary/15 text-primary"
                    ]}
                  >
                    {status_label(status)}
                    <span
                      :if={status == "pending"}
                      class="badge badge-sm ml-1.5 border-0 bg-warning/15 font-mono text-warning"
                    >
                      {@pending_count}
                    </span>
                  </button>
                <% end %>
              </div>

              <.form
                for={@filter_form}
                id="moderation-report-filters"
                phx-change="filter_reports"
                class="relative w-full lg:w-72"
              >
                <.icon
                  name="hero-magnifying-glass"
                  class="pointer-events-none absolute left-3 top-3.5 z-10 size-4 text-base-content/55"
                />
                <.input
                  field={@filter_form[:search]}
                  type="search"
                  aria-label="Search reports"
                  placeholder="Search reports"
                  autocomplete="off"
                  phx-debounce="250"
                  class="input input-bordered min-h-11 w-full rounded-xl border-base-300 bg-base-100 pl-10 text-sm focus:outline-2 focus:outline-offset-2 focus:outline-primary"
                />
              </.form>
            </div>
          </section>

          <div class="mb-3 mt-7 flex items-center justify-between text-sm text-base-content/60">
            <h2 class="font-bold text-base-content">{list_heading(@active_status)}</h2>
            <span>Newest first</span>
          </div>

          <div
            :if={@reports_empty?}
            id="reports-empty"
            class="rounded-2xl border border-dashed border-base-300 bg-base-200/45 px-6 py-14 text-center"
          >
            <div class="mx-auto grid size-11 place-items-center rounded-xl bg-primary/10 text-primary">
              <.icon name={empty_icon(@active_status)} class="size-5" />
            </div>
            <h3 class="mt-4 text-base font-bold text-base-content">{empty_title(@active_status)}</h3>
            <p class="mx-auto mt-1 max-w-md text-sm leading-6 text-base-content/60">
              {empty_message(@active_status, @search)}
            </p>
          </div>

          <div id="moderation-reports" phx-update="stream" class="space-y-3">
            <article
              :for={{dom_id, report} <- @streams.reports}
              id={dom_id}
              data-testid={"report-card-#{report.id}"}
              data-status={report.status}
              class="overflow-hidden rounded-2xl border border-base-300 bg-base-200"
            >
              <div class="p-4 sm:p-5">
                <div class="grid gap-5 lg:grid-cols-[minmax(0,1fr)_auto] lg:items-start">
                  <div class="min-w-0">
                    <div class="mb-2.5 flex flex-wrap items-center gap-2">
                      <span class={status_badge_class(report.status)}>
                        {status_label(report.status)}
                      </span>
                      <span class="badge badge-sm border-0 bg-base-300 text-base-content/65">
                        {String.capitalize(report.target_type)}
                      </span>
                      <span class="badge badge-sm border-0 bg-base-300 text-base-content/65">
                        {String.capitalize(report.reason)}
                      </span>
                    </div>
                    <h3 class="text-base font-bold leading-6 tracking-[-0.015em] text-base-content sm:text-lg">
                      {report.target_title}
                    </h3>
                    <p class="mt-1 text-sm text-base-content/60">
                      Reported by
                      <strong class="font-semibold text-base-content">
                        {report.reporter_username}
                      </strong>
                      · {LiveHelpers.format_short(report.inserted_at)}
                    </p>
                  </div>

                  <div :if={report.status == "pending"} class="grid grid-cols-2 gap-2 sm:flex">
                    <button
                      id={"resolve-report-#{report.id}"}
                      phx-click="resolve"
                      phx-value-report_id={report.id}
                      class="btn btn-primary btn-sm min-h-10"
                      data-testid="resolve-button"
                    >
                      Resolve
                    </button>
                    <button
                      id={"approve-report-#{report.id}"}
                      phx-click="approve"
                      phx-value-report_id={report.id}
                      class="btn btn-outline btn-sm min-h-10"
                      data-testid="approve-button"
                    >
                      Approve
                    </button>
                    <button
                      id={"dismiss-report-#{report.id}"}
                      phx-click="dismiss"
                      phx-value-report_id={report.id}
                      class="btn btn-ghost btn-sm col-span-2 min-h-10"
                      data-testid="dismiss-button"
                    >
                      Dismiss
                    </button>
                  </div>
                </div>

                <div :if={report.description} class="mt-4 rounded-xl bg-base-100/65 px-4 py-3">
                  <p class="text-sm leading-6 text-base-content">{report.description}</p>
                </div>

                <details :if={report.status == "pending"} class="group mt-3">
                  <summary class="inline-flex cursor-pointer list-none items-center gap-1.5 rounded-lg px-2 py-1.5 text-xs font-bold text-base-content/60 hover:bg-base-300 hover:text-base-content focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary">
                    <.icon name="hero-pencil-square" class="size-4" /> Add moderation note
                  </summary>
                  <.form
                    for={report.note_form}
                    id={"report-note-form-#{report.id}"}
                    phx-submit="add_notes"
                    phx-value-report_id={report.id}
                    class="mt-2 flex flex-col gap-2 sm:flex-row"
                  >
                    <.input
                      field={report.note_form[:notes]}
                      type="text"
                      label="Moderation note"
                      placeholder="Add context for the next moderator"
                      maxlength="500"
                      class="input input-bordered min-h-11 w-full rounded-xl border-base-300 bg-base-100"
                    />
                    <button type="submit" class="btn btn-outline min-h-11 sm:mt-0">
                      Save note
                    </button>
                  </.form>
                </details>
              </div>

              <footer
                id={"report-history-#{report.id}"}
                class="grid gap-3 border-t border-base-300 bg-base-100/35 px-4 py-3 text-xs leading-5 text-base-content/65 sm:grid-cols-[auto_minmax(0,1fr)_auto] sm:items-start sm:px-5"
              >
                <span class={history_icon_class(report.status)}>
                  <.icon name={history_icon(report.status)} class="size-3.5" />
                </span>
                <p>
                  <%= if report.status == "pending" do %>
                    Report received from
                    <strong class="font-semibold text-base-content">
                      {report.reporter_username}
                    </strong>
                    · {LiveHelpers.format_short(report.inserted_at)}
                    <span :if={present?(report.resolution_notes)}>
                      · “{report.resolution_notes}”
                    </span>
                  <% else %>
                    <strong class="font-semibold text-base-content">
                      {reviewer_label(report.reviewer_username)}
                    </strong>
                    {status_action(report.status)} this · {LiveHelpers.format_short(
                      report.resolved_at
                    )}
                    <span :if={present?(report.resolution_notes)}>
                      · “{report.resolution_notes}”
                    </span>
                  <% end %>
                </p>
                <a
                  :if={report.target_path}
                  id={"report-target-link-#{report.id}"}
                  href={report.target_path}
                  target="_blank"
                  rel="noopener noreferrer"
                  class="inline-flex items-center gap-1 font-bold text-primary hover:underline hover:underline-offset-4"
                >
                  {target_link_label(report.target_type)}
                  <.icon name="hero-arrow-top-right-on-square" class="size-3.5" />
                </a>
              </footer>
            </article>
          </div>

          <div
            :if={@has_more}
            id="infinite-scroll-marker"
            phx-hook="InfiniteScroll"
            class="flex h-20 items-center justify-center"
          >
            <span
              class="loading loading-dots loading-sm text-primary"
              aria-label="Loading more reports"
            >
            </span>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp review_report(socket, report_id, status, resolution_notes, success_message) do
    report = Forum.get_report!(report_id)

    case Forum.review_report(
           report,
           socket.assigns.current_user.id,
           status,
           preferred_notes(resolution_notes, report.resolution_notes)
         ) do
      {:ok, _report} ->
        {:noreply,
         socket
         |> assign(:page, 0)
         |> load_reports(reset: true)
         |> put_flash(:info, success_message)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "We couldn't update that report. Please try again.")}
    end
  end

  defp load_reports(socket, opts) do
    reports = fetch_reports(socket, 0)

    socket
    |> assign(:pending_count, Forum.count_pending_reports())
    |> assign(:reports_empty?, reports == [])
    |> assign(:has_more, length(reports) == @page_size)
    |> stream(:reports, serialize_reports(reports), opts)
  end

  defp fetch_reports(socket, page) do
    Forum.list_reports(
      status: socket.assigns.active_status,
      search: socket.assigns.search,
      limit: @page_size,
      offset: page * @page_size
    )
  end

  defp serialize_reports(reports) do
    Enum.map(reports, fn report ->
      {target_title, target_path, thread_id} = report_target(report)

      %{
        id: to_string(report.id),
        target_type: report.target_type,
        target_id: to_string(report.target_id),
        thread_id: thread_id,
        target_title: target_title,
        target_path: target_path,
        reason: report.reason,
        description: report.description,
        status: report.status,
        reporter_username: report.user.username,
        reviewer_username: report.reviewed_by && report.reviewed_by.username,
        inserted_at: report.inserted_at,
        resolved_at: report.resolved_at,
        resolution_notes: report.resolution_notes,
        note_form:
          to_form(%{"notes" => note_value(report.resolution_notes)},
            as: :moderation_note,
            id: "moderation-note-#{report.id}"
          )
      }
    end)
  end

  defp report_target(%{target_type: "thread"} = report) do
    case Forum.get_thread(report.target_id) do
      nil -> {"Deleted thread", nil, to_string(report.target_id)}
      thread -> {thread.title, "/forum/t/#{report.target_id}", to_string(report.target_id)}
    end
  end

  defp report_target(%{target_type: "comment"} = report) do
    case Forum.get_comment(report.target_id) do
      nil ->
        {"Deleted comment", nil, nil}

      comment ->
        excerpt = String.slice(comment.body, 0, 80)
        suffix = if String.length(comment.body) > 80, do: "…", else: ""

        {"“#{excerpt}#{suffix}”", "/forum/t/#{comment.thread_id}#comment-#{report.target_id}",
         to_string(comment.thread_id)}
    end
  end

  defp report_target(_report), do: {"Unavailable content", nil, nil}

  defp status_label("all"), do: "All"
  defp status_label(status), do: String.capitalize(status)

  defp list_heading("pending"), do: "Needs review"
  defp list_heading("all"), do: "All reports"
  defp list_heading(status), do: "#{status_label(status)} reports"

  defp status_badge_class("pending"),
    do: "badge badge-sm border-0 bg-warning/15 font-bold text-warning"

  defp status_badge_class("resolved"),
    do: "badge badge-sm border-0 bg-success/15 font-bold text-success"

  defp status_badge_class("reviewed"),
    do: "badge badge-sm border-0 bg-primary/15 font-bold text-primary"

  defp status_badge_class("dismissed"),
    do: "badge badge-sm border-0 bg-base-300 font-bold text-base-content/65"

  defp history_icon("pending"), do: "hero-inbox-arrow-down"
  defp history_icon("resolved"), do: "hero-check"
  defp history_icon("reviewed"), do: "hero-check-circle"
  defp history_icon("dismissed"), do: "hero-x-mark"

  defp history_icon_class("pending"),
    do: "grid size-6 place-items-center rounded-full bg-warning/15 text-warning"

  defp history_icon_class("resolved"),
    do: "grid size-6 place-items-center rounded-full bg-success/15 text-success"

  defp history_icon_class("reviewed"),
    do: "grid size-6 place-items-center rounded-full bg-primary/15 text-primary"

  defp history_icon_class("dismissed"),
    do: "grid size-6 place-items-center rounded-full bg-base-300 text-base-content/55"

  defp status_action("resolved"), do: "resolved"
  defp status_action("reviewed"), do: "approved"
  defp status_action("dismissed"), do: "dismissed"

  defp target_link_label("thread"), do: "View thread"
  defp target_link_label("comment"), do: "View comment"

  defp reviewer_label(nil), do: "A moderator"
  defp reviewer_label(username), do: username

  defp preferred_notes(nil, existing_notes), do: existing_notes
  defp preferred_notes(notes, _existing_notes), do: notes

  defp note_value(nil), do: ""
  defp note_value(notes), do: notes

  defp empty_icon("pending"), do: "hero-check-circle"
  defp empty_icon(_status), do: "hero-magnifying-glass"

  defp empty_title("pending"), do: "All caught up"
  defp empty_title(_status), do: "No reports found"

  defp empty_message(_status, search) when search != "",
    do: "Try a different search or clear the search field."

  defp empty_message("pending", _search), do: "There are no pending reports to review."
  defp empty_message(_status, _search), do: "There are no reports with this status yet."

  defp present?(value), do: is_binary(value) and String.trim(value) != ""
end
