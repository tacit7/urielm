defmodule UrielmWeb.Admin.UserManagementLive do
  use UrielmWeb, :live_view

  import UrielmWeb.AdminComponents

  alias Urielm.Accounts

  @page_size 25

  @impl true
  def mount(_params, _session, socket) do
    base_socket =
      socket
      |> assign(:page_title, "User Management")
      |> assign(:search, "")
      |> assign(:status_filter, nil)
      |> assign(:trust_filter, nil)
      |> assign(:flop, default_flop())

    if connected?(socket) do
      {:ok, load_users(base_socket)}
    else
      {:ok, assign(base_socket, users: [], meta: nil)}
    end
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
    trust =
      if level == "" do
        nil
      else
        case Integer.parse(level) do
          {n, ""} -> n
          _ -> nil
        end
      end

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
    page_num =
      case Integer.parse(page) do
        {n, ""} when n > 0 -> n
        _ -> 1
      end

    flop = %{socket.assigns.flop | page: page_num}

    {:noreply,
     socket
     |> assign(:flop, flop)
     |> load_users()}
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
      <div id="admin-users-page" class="ui-page-shell max-w-7xl">
        <header id="admin-users-header" class="ui-page-header ui-page-heading">
          <h1 class="ui-section-title">User management</h1>
          <p class="ui-section-copy">
            Search, filter, and review {@meta && @meta.total_count} user accounts.
          </p>
        </header>

        <.admin_nav current="users" />

        <section
          id="admin-user-filters"
          class="ui-card ui-card-compact mb-6 grid h-auto gap-3 p-3 sm:grid-cols-2 lg:grid-cols-[minmax(16rem,1fr)_auto_auto]"
          aria-label="User filters"
        >
          <form id="admin-user-search-form" phx-change="search" class="min-w-0">
            <input
              id="admin-user-search"
              type="text"
              name="search"
              value={@search}
              aria-label="Search users"
              placeholder="Search username or email"
              class="input input-bordered w-full"
              phx-debounce="300"
            />
          </form>

          <form id="admin-user-status-form" phx-change="filter_status">
            <select
              id="admin-user-status"
              name="status"
              aria-label="Filter by status"
              class="select select-bordered w-full"
            >
              <option value="">All statuses</option>
              <option value="active" selected={@status_filter == "active"}>Active</option>
              <option value="suspended" selected={@status_filter == "suspended"}>Suspended</option>
              <option value="silenced" selected={@status_filter == "silenced"}>Silenced</option>
            </select>
          </form>

          <form id="admin-user-trust-form" phx-change="filter_trust">
            <select
              id="admin-user-trust"
              name="trust_level"
              aria-label="Filter by trust level"
              class="select select-bordered w-full"
            >
              <option value="">All trust levels</option>
              <option value="0" selected={@trust_filter == 0}>TL0 · New</option>
              <option value="1" selected={@trust_filter == 1}>TL1 · Basic</option>
              <option value="2" selected={@trust_filter == 2}>TL2 · Member</option>
              <option value="3" selected={@trust_filter == 3}>TL3 · Regular</option>
              <option value="4" selected={@trust_filter == 4}>TL4 · Leader</option>
            </select>
          </form>
        </section>

        <section id="admin-users-table" class="ui-card h-auto">
          <div class="overflow-x-auto">
            <table class="table table-zebra w-full">
              <thead>
                <tr>
                  <th>User</th>
                  <th>
                    <button
                      phx-click="sort"
                      phx-value-field="email"
                      class="flex items-center gap-1 hover:text-primary"
                    >
                      Email <.sort_icon field="email" flop={@flop} />
                    </button>
                  </th>
                  <th>Role</th>
                  <th>
                    <button
                      phx-click="sort"
                      phx-value-field="trust_level"
                      class="flex items-center gap-1 hover:text-primary"
                    >
                      Trust <.sort_icon field="trust_level" flop={@flop} />
                    </button>
                  </th>
                  <th>Status</th>
                  <th>
                    <button
                      phx-click="sort"
                      phx-value-field="inserted_at"
                      class="flex items-center gap-1 hover:text-primary"
                    >
                      Joined <.sort_icon field="inserted_at" flop={@flop} />
                    </button>
                  </th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                <%= if @users == [] do %>
                  <tr>
                    <td colspan="7" class="text-center py-8 text-base-content/50">
                      No users found
                    </td>
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
                        <.link
                          navigate={~p"/admin/users/#{user.id}"}
                          class="btn btn-ghost btn-sm whitespace-nowrap"
                        >
                          Manage <.icon name="hero-chevron-right" class="size-4" />
                        </.link>
                      </td>
                    </tr>
                  <% end %>
                <% end %>
              </tbody>
            </table>
          </div>
        </section>

        <%= if @meta && @meta.total_pages > 1 do %>
          <nav class="join mt-6 flex justify-center" aria-label="User pages">
            <%= if @meta.has_previous_page? do %>
              <button
                phx-click="page"
                phx-value-page={@meta.current_page - 1}
                class="btn btn-sm join-item"
                aria-label="Previous page"
              >
                <.icon name="hero-chevron-left" class="size-4" /> Previous
              </button>
            <% end %>

            <span class="btn btn-sm btn-disabled join-item">
              Page {@meta.current_page} of {@meta.total_pages}
            </span>

            <%= if @meta.has_next_page? do %>
              <button
                phx-click="page"
                phx-value-page={@meta.current_page + 1}
                class="btn btn-sm join-item"
                aria-label="Next page"
              >
                Next <.icon name="hero-chevron-right" class="size-4" />
              </button>
            <% end %>
          </nav>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  defp sort_icon(assigns) do
    field = assigns.field
    flop = assigns.flop

    cond do
      flop[:order_by] == [field] && flop[:order_directions] == [:asc] ->
        ~H[<.icon name="hero-chevron-up" class="size-3.5" />]

      flop[:order_by] == [field] && flop[:order_directions] == [:desc] ->
        ~H[<.icon name="hero-chevron-down" class="size-3.5" />]

      true ->
        ~H[<.icon name="hero-arrows-up-down" class="size-3.5 opacity-30" />]
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
    page =
      Map.get(params, "page", "1")
      |> case do
        p when is_binary(p) ->
          case Integer.parse(p) do
            {n, ""} when n > 0 -> n
            _ -> 1
          end

        p when is_integer(p) ->
          p
      end

    %{default_flop() | page: page}
  end

  @sortable_fields ~w(email trust_level inserted_at)

  defp toggle_sort(flop, field) do
    if field not in @sortable_fields do
      flop
    else
      field_atom = String.to_existing_atom(field)

      if flop[:order_by] == [field_atom] && flop[:order_directions] == [:asc] do
        %{flop | order_by: [field_atom], order_directions: [:desc]}
      else
        %{flop | order_by: [field_atom], order_directions: [:asc]}
      end
    end
  end
end
