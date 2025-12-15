defmodule UrielmWeb.Admin.ModerationQueueLive do
  use UrielmWeb, :live_view

  alias Urielm.Forum
  alias Urielm.Repo

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
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100">
      <div class="container mx-auto px-4 py-8 max-w-5xl">
        <div class="mb-8">
          <h1 class="text-3xl font-bold text-base-content">Moderation Queue</h1>
          <p class="text-base-content/60 mt-2">
            <span class="badge badge-lg badge-error">{@pending_count}</span>
            pending reports
          </p>
        </div>

        <%= if length(@reports) == 0 do %>
          <div class="card bg-base-200 border border-base-300">
            <div class="card-body text-center py-12">
              <p class="text-lg font-medium text-base-content">All caught up!</p>
              <p class="text-sm text-base-content/60">No pending reports at this time.</p>
            </div>
          </div>
        <% else %>
          <div class="space-y-4">
            <%= for report <- @reports do %>
              <div class="card bg-base-200 border border-base-300">
                <div class="card-body">
                  <div class="flex justify-between items-start mb-4">
                    <div>
                      <div class="flex items-center gap-2 mb-2">
                        <span class="badge badge-sm">
                          <%= String.capitalize(report.target_type) %>
                        </span>
                        <span class="badge badge-sm badge-warning">
                          <%= String.capitalize(report.reason) %>
                        </span>
                      </div>
                      <h2 class="text-lg font-semibold text-base-content">
                        Reported by {report.reporter_username}
                      </h2>
                      <p class="text-sm text-base-content/60 mt-1">
                        {format_time(report.inserted_at)}
                      </p>
                    </div>

                    <div class="flex gap-2">
                      <button
                        phx-click="approve"
                        phx-value-report_id={report.id}
                        class="btn btn-sm btn-success"
                      >
                        Approve
                      </button>
                      <button
                        phx-click="resolve"
                        phx-value-report_id={report.id}
                        class="btn btn-sm btn-primary"
                      >
                        Resolve
                      </button>
                      <button
                        phx-click="dismiss"
                        phx-value-report_id={report.id}
                        class="btn btn-sm btn-ghost"
                      >
                        Dismiss
                      </button>
                    </div>
                  </div>

                  <%= if report.description do %>
                    <div class="bg-base-300 rounded p-3 my-3">
                      <p class="text-sm text-base-content">{report.description}</p>
                    </div>
                  <% end %>

                  <div class="divider my-2"></div>

                  <div class="flex justify-between text-xs text-base-content/60">
                    <span>Target ID: {String.slice(report.target_id, 0, 8)}</span>
                    <span>Report ID: {String.slice(report.id, 0, 8)}</span>
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
    """
  end

  defp serialize_reports(reports) do
    Enum.map(reports, fn report ->
      reporter = Repo.get(Urielm.Accounts.User, report.user_id)

      %{
        id: to_string(report.id),
        target_type: report.target_type,
        target_id: to_string(report.target_id),
        reason: report.reason,
        description: report.description,
        status: report.status,
        reporter_username: reporter.username,
        inserted_at: report.inserted_at
      }
    end)
  end

  defp format_time(datetime) do
    now = DateTime.utc_now()
    seconds_ago = DateTime.diff(now, datetime, :second)

    cond do
      seconds_ago < 60 -> "now"
      seconds_ago < 3600 -> "#{div(seconds_ago, 60)}m ago"
      seconds_ago < 86400 -> "#{div(seconds_ago, 3600)}h ago"
      true -> Calendar.strftime(datetime, "%b %d, %Y")
    end
  end
end
