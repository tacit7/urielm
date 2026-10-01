defmodule Mix.Tasks.Forum.CreateEddyPost do
  @moduledoc """
  Creates Eddy Thornfield account and his marketing tools question post.

      mix forum.create_eddy_post
  """

  use Mix.Task

  alias Urielm.Accounts
  alias Urielm.Forum

  @shortdoc "Creates Eddy's account and marketing tools post"
  @requirements ["app.config"]

  @impl Mix.Task
  def run(_args) do
    start_dependencies!()

    # Create or get Eddy's account
    eddy = ensure_eddy_user!()

    # Create the post
    create_marketing_post!(eddy)
  end

  defp ensure_eddy_user! do
    email = "eddy.thornfield@urielm.dev"

    case Accounts.get_user_by_email(email) do
      nil ->
        case Accounts.register_user(%{
               email: email,
               username: "eddy-thornfield",
               display_name: "Eddy Thornfield",
               password: "SecurePass2024!"
             }) do
          {:ok, user} ->
            Mix.shell().info("✓ Created user: #{user.display_name} (@#{user.username})")
            user

          {:error, changeset} ->
            fail!("Could not create user: #{format_error(changeset)}")
        end

      user ->
        Mix.shell().info("✓ User already exists: #{user.display_name} (@#{user.username})")
        user
    end
  end

  defp create_marketing_post!(user) do
    qa_board = Forum.get_board("qa")

    unless qa_board do
      fail!("Q&A board not found. Run 'mix run priv/repo/seeds_forum.exs' first")
    end

    title = "Which tools or processes are must have for marketing?"

    body = """
    I had been using AI like a caveman for my marketing job until recently when I realized if that didn't change, I would fall behind.

    I was hoping some people using AI for marketing could name some tools or processes involving AI that they just couldn't do their jobs without.
    """

    slug = "which-tools-or-processes-are-must-have-for"

    case Forum.create_thread(qa_board.id, user.id, %{
           "title" => title,
           "body" => body,
           "slug" => slug
         }) do
      {:ok, thread} ->
        Mix.shell().info("""
        ✓ Created forum thread:
        ID: #{thread.id}
        Title: #{thread.title}
        Board: Q&A Help Desk
        URL: https://urielm.dev/forum/t/#{thread.id}
        """)

        thread

      {:error, changeset} ->
        if duplicate_error?(changeset) do
          Mix.shell().info("Thread already exists with that title or slug")
        else
          fail!("Could not create thread: #{format_error(changeset)}")
        end
    end
  end

  defp duplicate_error?(%Ecto.Changeset{errors: errors}) do
    Enum.any?(errors, fn
      {:slug, {_msg, [constraint: :unique, constraint_name: _]}} -> true
      _ -> false
    end)
  end

  defp start_dependencies! do
    # Start the full application to get RateLimiter and other processes
    case Application.ensure_all_started(:urielm) do
      {:ok, _apps} -> :ok
      {:error, reason} -> fail!("Could not start :urielm: #{inspect(reason)}")
    end
  end

  defp format_error(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> inspect()
  end

  defp format_error(reason), do: inspect(reason)

  defp fail!(message) do
    Mix.shell().error(message)
    Mix.raise(message)
  end
end
