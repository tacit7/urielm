# Create forum test data
alias Urielm.Repo
alias Urielm.Forum
alias Urielm.Accounts

# Create test users if they don't exist
user1 = Repo.get_by(Accounts.User, email: "alice@example.com") ||
  Repo.insert!(%Accounts.User{
    email: "alice@example.com",
    username: "alice",
    password_hash: Bcrypt.hash_pwd_salt("password123"),
    email_verified: true
  })

user2 = Repo.get_by(Accounts.User, email: "bob@example.com") ||
  Repo.insert!(%Accounts.User{
    email: "bob@example.com",
    username: "bob",
    password_hash: Bcrypt.hash_pwd_salt("password123"),
    email_verified: true
  })

user3 = Repo.get_by(Accounts.User, email: "charlie@example.com") ||
  Repo.insert!(%Accounts.User{
    email: "charlie@example.com",
    username: "charlie",
    password_hash: Bcrypt.hash_pwd_salt("password123"),
    email_verified: true
  })

IO.puts("Created users: alice, bob, charlie")

# Create categories and boards
category = Repo.get_by(Forum.Category, slug: "general-discussion") ||
  (case Forum.create_category(%{
    "name" => "General Discussion",
    "slug" => "general-discussion",
    "description" => "General discussions about anything"
  }) do
    {:ok, cat} -> cat
    {:error, _} -> Repo.get_by(Forum.Category, slug: "general-discussion")
  end)

board1 = Repo.get_by(Forum.Board, slug: "general") ||
  (case Forum.create_board(%{
    "name" => "General",
    "slug" => "general",
    "description" => "Off-topic discussions and announcements",
    "category_id" => category.id
  }) do
    {:ok, b} -> b
    {:error, _} -> Repo.get_by(Forum.Board, slug: "general")
  end)

board2 = Repo.get_by(Forum.Board, slug: "help-support") ||
  (case Forum.create_board(%{
    "name" => "Help & Support",
    "slug" => "help-support",
    "description" => "Get help with common issues",
    "category_id" => category.id
  }) do
    {:ok, b} -> b
    {:error, _} -> Repo.get_by(Forum.Board, slug: "help-support")
  end)

board3 = Repo.get_by(Forum.Board, slug: "feature-requests") ||
  (case Forum.create_board(%{
    "name" => "Feature Requests",
    "slug" => "feature-requests",
    "description" => "Suggest new features and improvements",
    "category_id" => category.id
  }) do
    {:ok, b} -> b
    {:error, _} -> Repo.get_by(Forum.Board, slug: "feature-requests")
  end)

IO.puts("Boards ready: general, help-support, feature-requests")

# Create threads
thread_data = [
  {board1, user1, "Welcome to the Forum!", "This is the general discussion board. Feel free to post about anything you'd like. This is a great place to connect with other members of our community and share your thoughts, ideas, and experiences."},
  {board2, user2, "How do I get started with Phoenix?", "I'm new to Phoenix and want to learn how to build web applications with it. Can anyone recommend good resources or tutorials? I already know Elixir but haven't used Phoenix yet."},
  {board1, user3, "LiveView is amazing!", "Just finished my first Phoenix LiveView project and I have to say, it's incredibly productive. The ability to build real-time features without JavaScript is a game changer. Highly recommend it to anyone building interactive web apps."},
  {board3, user1, "Feature Request: Dark Mode", "It would be great to have a dark mode option. Many users prefer dark interfaces for reduced eye strain, especially when working at night. This could be toggled in user settings."},
  {board2, user2, "How to handle errors in Elixir?", "I'm trying to understand Elixir's approach to error handling. Should I use try/catch or return tuples? What's the idiomatic way? Looking for examples and best practices."},
  {board1, user3, "Ecto queries are powerful", "Been working with Ecto for a while now and I'm impressed by how expressive the query API is. Being able to build complex queries in Elixir without raw SQL is fantastic. Anyone else love Ecto as much as I do?"}
]

created_threads = Enum.map(thread_data, fn {board, user, title, body} ->
  slug = title
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")

  {:ok, thread} = Forum.create_thread(board.id, user.id, %{
    "title" => title,
    "body" => body,
    "slug" => slug
  })
  thread
end)

IO.puts("Created #{length(created_threads)} threads")

# Add some comments to threads
{:ok, _comment1} = Forum.create_comment(
  List.first(created_threads).id,
  user2.id,
  %{"body" => "Great to be here! Looking forward to great discussions."}
)

{:ok, _comment2} = Forum.create_comment(
  Enum.at(created_threads, 1).id,
  user1.id,
  %{"body" => "Check out the official Phoenix guides on phoenixframework.org - they're excellent!"}
)

{:ok, _comment3} = Forum.create_comment(
  Enum.at(created_threads, 2).id,
  user2.id,
  %{"body" => "Completely agree! The developer experience is top notch."}
)

IO.puts("Created comments")

# Add some votes
Enum.each(created_threads, fn thread ->
  {:ok, _} = Forum.cast_vote(user2.id, "thread", thread.id, 1)
  {:ok, _} = Forum.cast_vote(user3.id, "thread", thread.id, 1)
end)

IO.puts("Added votes to threads")

# Create some tags
{:ok, tag1} = Forum.create_tag(%{"name" => "Phoenix", "slug" => "phoenix"})
{:ok, tag2} = Forum.create_tag(%{"name" => "Elixir", "slug" => "elixir"})
{:ok, tag3} = Forum.create_tag(%{"name" => "Help", "slug" => "help"})
{:ok, tag4} = Forum.create_tag(%{"name" => "Feature", "slug" => "feature"})

IO.puts("Created tags")

# Tag some threads
Forum.add_tag_to_thread(Enum.at(created_threads, 1).id, tag1.id)
Forum.add_tag_to_thread(Enum.at(created_threads, 1).id, tag2.id)
Forum.add_tag_to_thread(Enum.at(created_threads, 1).id, tag3.id)

Forum.add_tag_to_thread(Enum.at(created_threads, 2).id, tag1.id)
Forum.add_tag_to_thread(Enum.at(created_threads, 2).id, tag2.id)

Forum.add_tag_to_thread(Enum.at(created_threads, 3).id, tag4.id)

Forum.add_tag_to_thread(Enum.at(created_threads, 4).id, tag2.id)
Forum.add_tag_to_thread(Enum.at(created_threads, 4).id, tag3.id)

IO.puts("Tagged threads")

IO.puts("\n✅ Forum seed data created successfully!")
IO.puts("\nTest Accounts:")
IO.puts("  alice@example.com / password123")
IO.puts("  bob@example.com / password123")
IO.puts("  charlie@example.com / password123")
