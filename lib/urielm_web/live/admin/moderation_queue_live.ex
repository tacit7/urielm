defmodule UrielmWeb.Admin.ModerationQueueLive do
  use UrielmWeb, :live_view

  alias Urielm.Forum
  alias UrielmWeb.LiveHelpers

  @page_size 20

  @impl true
  def mount(_params, _session, socket) do
    if socket.assigns.current_user && socket.assigns.current_user.is_admin do
      pending_count = Forum.count_pending_reports()
      reports = Forum.list_reports(status: "pending", limit: @page_size, offset: 0)

      {:ok,
       socket
       |> assign(:page_title, "Moderation Queue")
       |> assign(:reports, serialize_reports(reports))
       |> assign(:pending_count, pending_count)
       |> assign(:page, 0)
       |> assign(:has_more, length(reports) == @page_size)}
    else
      {:ok, redirect(socket, to: "/")}
    end
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    %{page: page, has_more: has_more} = socket.assigns

    if not has_more do
      {:noreply, socket}
    else
      offset = (page + 1) * @page_size
      reports = Forum.list_reports(status: "pending", limit: @page_size, offset: offset)

      {:noreply,
       socket
       |> assign(:page, page + 1)
       |> assign(:has_more, length(reports) == @page_size)
       |> assign(:reports, socket.assigns.reports ++ serialize_reports(reports))}
    end
  end

  @impl true
  def handle_event("approve", %{"report_id" => report_id}, socket) do
    report = Forum.get_report!(report_id)

    case Forum.review_report(report, socket.assigns.current_user.id, "reviewed", "Approved") do
      {:ok, _} ->
        # Remove from view and update count
        {:noreply,
         socket
         |> update(:reports, fn reports ->
           Enum.filter(reports, &(&1.id != report_id))
         end)
         |> update(:pending_count, &(&1 - 1))
         |> put_flash(:info, "Report approved")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to approve report")}
    end
  end

  @impl true
  def handle_event("resolve", %{"report_id" => report_id}, socket) do
    report = Forum.get_report!(report_id)

    case Forum.review_report(report, socket.assigns.current_user.id, "resolved", nil) do
      {:ok, _} ->
        # Remove from view and update count
        {:noreply,
         socket
         |> update(:reports, fn reports ->
           Enum.filter(reports, &(&1.id != report_id))
         end)
         |> update(:pending_count, &(&1 - 1))
         |> put_flash(:info, "Report resolved")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to resolve report")}
    end
  end

  @impl true
  def handle_event("dismiss", %{"report_id" => report_id}, socket) do
    report = Forum.get_report!(report_id)

    case Forum.review_report(report, socket.assigns.current_user.id, "dismissed", nil) do
      {:ok, _} ->
        # Remove from view and update count
        {:noreply,
         socket
         |> update(:reports, fn reports ->
           Enum.filter(reports, &(&1.id != report_id))
         end)
         |> update(:pending_count, &(&1 - 1))
         |> put_flash(:info, "Report dismissed")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to dismiss report")}
    end
  end

  @impl true
  def handle_event("add_notes", %{"report_id" => report_id, "notes" => notes}, socket) do
    report = Forum.get_report!(report_id)

    case Forum.update_report_notes(report, notes) do
      {:ok, _} ->
        {:noreply, put_flash(socket, :info, "Notes saved")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to save notes")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user} current_page="admin" socket={@socket}>
      <div class="min-h-screen bg-base-100">
        <div class="container mx-auto px-4 py-8 max-w-5xl">
          <div class="mb-8">
            <h1 class="text-3xl font-bold text-base-content">Moderation Queue</h1>
            <p class="text-base-content/60 mt-2">
              <span class="badge badge-lg badge-error">{@pending_count}</span> pending reports
            </p>
          </div>

          <%= if length(@reports) == 0 do %>
            <div id="reports-empty" class="card bg-base-200 border border-base-300">
              <div class="card-body text-center py-12">
                <p class="text-lg font-medium text-base-content">All caught up!</p>
                <p class="text-sm text-base-content/60">No pending reports at this time.</p>
              </div>
            </div>
          <% else %>
            <div class="space-y-4">
              <%= for report <- @reports do %>
                <div
                  class="card bg-base-200 border border-base-300"
                  data-testid={"report-card-#{report.id}"}
                >
                  <div class="card-body">
                    <div class="flex justify-between items-start mb-4">
                      <div class="flex-1">
                        <div class="flex items-center gap-2 mb-2">
                          <span class="badge badge-sm">
                            {String.capitalize(report.target_type)}
                          </span>
                          <span class="badge badge-sm badge-warning">
                            {String.capitalize(report.reason)}
                          </span>
                        </div>
                        <h2 class="text-lg font-semibold text-base-content mb-1">
                          {report.target_title}
                        </h2>
                        <p class="text-sm text-base-content/60">
                          Reported by
                          <span class="font-medium text-base-content">
                            {report.reporter_username}
                          </span>
                          {LiveHelpers.format_short(report.inserted_at)}
                        </p>
                      </div>

                      <div class="flex gap-2">
                        <button
                          phx-click="approve"
                          phx-value-report_id={report.id}
                          class="btn btn-sm btn-success"
                          data-testid="approve-button"
                        >
                          Approve
                        </button>
                        <button
                          phx-click="resolve"
                          phx-value-report_id={report.id}
                          class="btn btn-sm btn-primary"
                          data-testid="resolve-button"
                        >
                          Resolve
                        </button>
                        <button
                          phx-click="dismiss"
                          phx-value-report_id={report.id}
                          class="btn btn-sm btn-ghost"
                          data-testid="dismiss-button"
                        >
                          Dismiss
                        </button>
                      </div>
                    </div>

                    <%= if report.description do %>
                      <div class="bg-base-300 rounded p-3 my-3">
                        <p class="text-xs text-base-content/60 mb-1">Report reason:</p>
                        <p class="text-sm text-base-content">{report.description}</p>
                      </div>
                    <% end %>

                    <div class="my-4">
                      <form phx-submit="add_notes" class="flex gap-2">
                        <input
                          type="hidden"
                          name="report_id"
                          value={report.id}
                        />
                        <input
                          type="text"
                          name="notes"
                          placeholder="Add moderation notes..."
                          class="input input-bordered input-sm flex-1"
                          maxlength="500"
                        />
                        <button type="submit" class="btn btn-sm btn-outline">
                          Save notes
                        </button>
                      </form>
                    </div>

                    <div class="divider my-2"></div>

                    <div class="flex justify-between items-center">
                      <div class="flex gap-2">
                        <%= if report.target_type == "thread" do %>
                          <a
                            href={"/forum/t/#{report.target_id}"}
                            target="_blank"
                            rel="noopener noreferrer"
                            class="link link-primary text-sm"
                          >
                            View thread ↗
                          </a>
                        <% end %>
                        <%= if report.target_type == "comment" && report.thread_id do %>
                          <a
                            href={"/forum/t/#{report.thread_id}#comment-#{report.target_id}"}
                            target="_blank"
                            rel="noopener noreferrer"
                            class="link link-primary text-sm"
                          >
                            View in thread ↗
                          </a>
                        <% end %>
                      </div>
                      <div class="text-xs text-base-content/60">
                        <span>Report ID: {String.slice(report.id, 0, 8)}</span>
                      </div>
                    </div>
                  </div>
                </div>
              <% end %>

              <%= if @has_more do %>
                <div
                  id="infinite-scroll-marker"
                  phx-hook="InfiniteScroll"
                  class="h-20 flex items-center justify-center"
                >
                  <div class="text-base-content/40 text-sm">Loading more...</div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp serialize_reports(reports) do
    Enum.map(reports, fn report ->
      # Fetch target content (thread or comment) title
      target_title =
        case report.target_type do
          "thread" ->
            try do
              # Fetch thread metadata only (no comments needed for moderation queue)
              thread = Forum.get_thread!(report.target_id)
              thread.title
            rescue
              Ecto.NoResultsError -> "Deleted thread"
            end

          "comment" ->
            try do
              comment = Forum.get_comment!(report.target_id)
              String.slice(comment.body, 0, 80) <> "..."
            rescue
              Ecto.NoResultsError -> "Deleted comment"
            end

          _ ->
            "Unknown"
        end

      # For comments, we need to fetch the thread to create a proper link
      thread_id =
        case report.target_type do
          "thread" ->
            to_string(report.target_id)

          "comment" ->
            try do
              comment = Forum.get_comment!(report.target_id)
              to_string(comment.thread_id)
            rescue
              Ecto.NoResultsError -> nil
            end

          _ ->
            nil
        end

      %{
        id: to_string(report.id),
        target_type: report.target_type,
        target_id: to_string(report.target_id),
        thread_id: thread_id,
        target_title: target_title,
        reason: report.reason,
        description: report.description,
        status: report.status,
        reporter_username: report.user.username,
        inserted_at: report.inserted_at
      }
    end)
  end

  # concise time formatting moved to LiveHelpers
end
