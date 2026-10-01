# Script to create Eddy's account and marketing post
# Run with: ./run_mix_prod.sh run create_eddy_post.exs

alias Urielm.{Accounts, Forum, Repo}

# Create or get Eddy's account
eddy_user =
  case Accounts.get_user_by_email("eddy.thornfield@urielm.dev") do
    nil ->
      {:ok, user} = Accounts.register_user(%{
        email: "eddy.thornfield@urielm.dev",
        username: "eddy-thornfield",
        display_name: "Eddy Thornfield",
        password: "SecurePass2024!"
      })

      IO.puts("✓ Created user: #{user.display_name} (@#{user.username})")
      user

    user ->
      IO.puts("✓ User already exists: #{user.display_name} (@#{user.username})")
      user
  end

# Get Q&A board
qa_board = Forum.get_board("qa")

unless qa_board do
  IO.puts("❌ Q&A board not found")
  System.halt(1)
end

# Create the post
title = "Which tools or processes are must have for marketing?"

body = """
I had been using AI like a caveman for my marketing job until recently when I realized if that didn't change, I would fall behind.

I was hoping some people using AI for marketing could name some tools or processes involving AI that they just couldn't do their jobs without.
"""

slug = "which-tools-or-processes-are-must-have-for"

case Forum.create_thread(qa_board.id, eddy_user.id, %{
       "title" => title,
       "body" => body,
       "slug" => slug
     }) do
  {:ok, thread} ->
    IO.puts("""
    ✓ Created forum thread:
    ID: #{thread.id}
    Title: #{thread.title}
    Board: Q&A Help Desk
    URL: https://urielm.dev/forum/t/#{thread.id}
    """)

  {:error, changeset} ->
    errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)

    if Map.has_key?(errors, :slug) do
      IO.puts("ℹ Thread with this slug already exists")
    else
      IO.puts("❌ Could not create thread: #{inspect(errors)}")
      System.halt(1)
    end
end
