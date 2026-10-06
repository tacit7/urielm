defmodule UrielmWeb.ForumVisibility do
  @moduledoc false

  import Phoenix.LiveView
  import Phoenix.Component, only: [assign: 3]

  alias Urielm.Accounts
  alias Urielm.Forum

  def attach(socket, resource) do
    attach_hook(socket, :forum_visibility, :handle_event, fn event, params, socket ->
      user = socket.assigns.current_user
      user = if user, do: Accounts.get_user(user.id)
      socket = assign(socket, :current_user, user)

      visible =
        case resource do
          :thread ->
            thread = socket.assigns.thread

            thread &&
              Forum.get_thread(thread.id,
                viewer: user,
                allow_removed?: user && user.is_admin
              )

          :video ->
            thread = socket.assigns.thread

            discussion_event? =
              event in [
                "create_comment",
                "edit_comment",
                "delete_comment",
                "open_report_comment",
                "report_comment"
              ] or (event == "vote" and params["target_type"] == "comment")

            if thread, do: Forum.get_thread(thread.id), else: not discussion_event?

          :board ->
            Forum.get_board(socket.assigns.board.slug, viewer: user)
        end

      if visible do
        {:cont, socket}
      else
        {:halt, socket |> put_flash(:error, "Discussion not found") |> redirect(to: "/")}
      end
    end)
  end
end
