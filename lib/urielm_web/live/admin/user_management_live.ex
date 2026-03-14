defmodule UrielmWeb.Admin.UserManagementLive do
  use UrielmWeb, :live_view

  import UrielmWeb.AdminComponents

  alias Urielm.Accounts

  @page_size 25

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "User Management")
     |> assign(:search, "")
     |> assign(:status_filter, nil)
     |> assign(:trust_filter, nil)
     |> assign(:flop, default_flop())
     |> load_users()}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    flop = parse_flop(params)

    {:noreply,
     socket
     |> assign(:flop, flop)
     |> load_users()}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    {:noreply,
     socket
     |> assign(:search, search)
     |> assign(:flop, default_flop())
     |> load_users()}
  end

  @impl true
  def handle_event("filter_status", %{"status" => status}, socket) do
    status = if status == "", do: nil, else: status

    {:noreply,
     socket
     |> assign(:status_filter, status)
     |> assign(:flop, default_flop())
     |> load_users()}
  end

  @impl true
  def handle_event("filter_trust", %{"trust_level" => level}, socket) do
    trust = if level == "", do: nil, else: String.to_integer(level)

    {:noreply,
     socket
     |> assign(:trust_filter, trust)
     |> assign(:flop, default_flop())
     |> load_users()}
  end

  @impl true
  def handle_event("sort", %{"field" => field}, socket) do
    flop = toggle_sort(socket.assigns.flop, field)

    {:noreply,
     socket
     |> assign(:flop, flop)
     |> load_users()}
  end

  @impl true
  def handle_event("page", %{"page" => page}, socket) do
    flop = %{socket.assigns.flop | page: String.to_integer(page)}

    {:noreply,
     socket
     |> assign(:flop, flop)
     |> load_users()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user} current_page="admin" socket={@socket}>
      <div class="min-h-screen bg-base-100">
        <div class="container mx-auto px-4 py-8 max-w-7xl">
          <div class="mb-6 flex items-center justify-between">
            <div>
              <h1 class="text-3xl font-bold text-base-content">User Management</h1>
              <p class="text-base-content/60 mt-1">
                {@meta && @meta.total_count} users
              </p>
            </div>
            <div class="flex gap-2">
              <a href="/admin/moderation" class="btn btn-ghost btn-sm">Moderation Queue</a>
              <a href="/admin/trust-levels" class="btn btn-ghost btn-sm">Trust Levels</a>
            </div>
          </div>

          <div class="flex flex-wrap gap-3 mb-6">
            <form phx-change="search" class="flex-1 min-w-48">
              <input
                type="text"
                name="search"
                value={@search}
                placeholder="Search username or email..."
                class="input input-bordered w-full"
                phx-debounce="300"
              />
            </form>

            <form phx-change="filter_status">
              <select name="status" class="select select-bordered">
                <option value="">All statuses</option>
                <option value="active" selected={@status_filter == "active"}>Active</option>
                <option value="suspended" selected={@status_filter == "suspended"}>Suspended</option>
                <option value="silenced" selected={@status_filter == "silenced"}>Silenced</option>
              </select>
            </form>

            <form phx-change="filter_trust">
              <select name="trust_level" class="select select-bordered">
                <option value="">All trust levels</option>
                <option value="0" selected={@trust_filter == 0}>TL0 - New</option>
                <option value="1" selected={@trust_filter == 1}>TL1 - Basic</option>
                <option value="2" selected={@trust_filter == 2}>TL2 - Member</option>
                <option value="3" selected={@trust_filter == 3}>TL3 - Regular</option>
                <option value="4" selected={@trust_filter == 4}>TL4 - Leader</option>
              </select>
            </form>
          </div>

          <div class="card bg-base-200 border border-base-300">
            <div class="overflow-x-auto">
              <table class="table table-zebra w-full">
                <thead>
                  <tr>
                    <th>User</th>
                    <th>
                      <button phx-click="sort" phx-value-field="email" class="flex items-center gap-1 hover:text-primary">
                        Email <.sort_icon field="email" flop={@flop} />
                      </button>
                    </th>
                    <th>Role</th>
                    <th>
                      <button phx-click="sort" phx-value-field="trust_level" class="flex items-center gap-1 hover:text-primary">
                        Trust <.sort_icon field="trust_level" flop={@flop} />
                      </button>
                    </th>
                    <th>Status</th>
                    <th>
                      <button phx-click="sort" phx-value-field="inserted_at" class="flex items-center gap-1 hover:text-primary">
                        Joined <.sort_icon field="inserted_at" flop={@flop} />
                      </button>
                    </th>
                    <th></th>
                  </tr>
                </thead>
                <tbody>
                  <%= if @users == [] do %>
                    <tr>
                      <td colspan="7" class="text-center py-8 text-base-content/50">No users found</td>
                    </tr>
                  <% else %>
                    <%= for user <- @users do %>
                      <tr class="hover">
                        <td>
                          <div class="flex items-center gap-3">
                            <div class="avatar">
                              <div class="w-9 rounded-full">
                                <%= if user.avatar_url do %>
                                  <img src={user.avatar_url} alt={user.username} />
                                <% else %>
                                  <div class="bg-base-300 w-9 h-9 rounded-full flex items-center justify-center text-sm font-bold">
                                    {String.first(user.username || "?")}
                                  </div>
                                <% end %>
                              </div>
                            </div>
                            <div>
                              <div class="font-medium text-base-content">{user.username}</div>
                              <%= if user.display_name && user.display_name != user.username do %>
                                <div class="text-xs text-base-content/50">{user.display_name}</div>
                              <% end %>
                            </div>
                          </div>
                        </td>
                        <td class="text-sm text-base-content/70">{user.email}</td>
                        <td><.role_badge user={user} /></td>
                        <td>
                          <span class="badge badge-sm badge-ghost">TL{user.trust_level}</span>
                        </td>
                        <td><.status_badge user={user} /></td>
                        <td class="text-xs text-base-content/50">
                          {Calendar.strftime(user.inserted_at, "%b %d, %Y")}
                        </td>
                        <td>
                          <a href={"/admin/users/#{user.id}"} class="btn btn-xs btn-ghost">
                            Manage →
                          </a>
                        </td>
                      </tr>
                    <% end %>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>

          <%= if @meta && @meta.total_pages > 1 do %>
            <div class="flex justify-center gap-2 mt-6">
              <%= if @meta.has_previous_page? do %>
                <button phx-click="page" phx-value-page={@meta.current_page - 1} class="btn btn-sm btn-ghost">
                  ← Prev
                </button>
              <% end %>

              <span class="btn btn-sm btn-disabled">
                Page {@meta.current_page} of {@meta.total_pages}
              </span>

              <%= if @meta.has_next_page? do %>
                <button phx-click="page" phx-value-page={@meta.current_page + 1} class="btn btn-sm btn-ghost">
                  Next →
                </button>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp role_badge(assigns) do
    cond do
      assigns.user.is_admin ->
        ~H[<span class="badge badge-sm badge-error">Admin</span>]

      assigns.user.is_moderator ->
        ~H[<span class="badge badge-sm badge-warning">Mod</span>]

      true ->
        ~H[<span class="badge badge-sm badge-ghost">User</span>]
    end
  end

  defp status_badge(assigns) do
    cond do
      User.suspended?(assigns.user) ->
        ~H[<span class="badge badge-sm badge-error">Suspended</span>]

      User.silenced?(assigns.user) ->
        ~H[<span class="badge badge-sm badge-warning">Silenced</span>]

      true ->
        ~H[<span class="badge badge-sm badge-success">Active</span>]
    end
  end

  defp sort_icon(assigns) do
    field = assigns.field
    flop = assigns.flop

    cond do
      flop[:order_by] == [field] && flop[:order_directions] == [:asc] ->
        ~H[<span>↑</span>]

      flop[:order_by] == [field] && flop[:order_directions] == [:desc] ->
        ~H[<span>↓</span>]

      true ->
        ~H[<span class="opacity-30">↕</span>]
    end
  end

  defp load_users(socket) do
    %{search: search, status_filter: status, trust_filter: trust, flop: flop} = socket.assigns

    flop_params =
      flop
      |> Map.merge(trust_filter_flop(trust))

    opts = [search: search, status: status]

    case Accounts.paginate_users(flop_params, opts) do
      {:ok, {users, meta}} ->
        socket
        |> assign(:users, users)
        |> assign(:meta, meta)

      {:error, _meta} ->
        socket
        |> assign(:users, [])
        |> assign(:meta, nil)
    end
  end

  defp trust_filter_flop(nil), do: %{}

  defp trust_filter_flop(level) do
    %{
      filters: [%{field: :trust_level, op: :==, value: level}]
    }
  end

  defp default_flop do
    %{
      page: 1,
      page_size: @page_size,
      order_by: [:inserted_at],
      order_directions: [:desc]
    }
  end

  defp parse_flop(params) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    %{default_flop() | page: page}
  end

  @sortable_fields ~w(email trust_level inserted_at)

  defp toggle_sort(flop, field) do
    if field not in @sortable_fields do
      flop
    else
      field_atom = String.to_atom(field)

      if flop[:order_by] == [field_atom] && flop[:order_directions] == [:asc] do
        %{flop | order_by: [field_atom], order_directions: [:desc]}
      else
        %{flop | order_by: [field_atom], order_directions: [:asc]}
      end
    end
  end
end
