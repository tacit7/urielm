import Ecto.Query
alias Urielm.Repo
alias Urielm.Learning.Course
alias Urielm.Learning.Lesson

# Remove duplicates — keep only course id 1 (ChatGPT for Beginners)
Repo.query!("DELETE FROM lessons WHERE course_id > 1")
Repo.query!("DELETE FROM courses WHERE id > 1")
IO.puts("Cleaned up duplicate courses.")

defmodule SeedHelper do
  def insert_course(attrs, lessons) do
    {:ok, course} =
      %Course{}
      |> Course.changeset(attrs)
      |> Repo.insert()

    for {num, title, vid_id} <- lessons do
      %Lesson{}
      |> Lesson.changeset(%{
        course_id: course.id,
        lesson_number: num,
        title: title,
        youtube_video_id: vid_id
      })
      |> Repo.insert!()
    end

    IO.puts("  ✓ #{course.title} (#{length(lessons)} lessons)")
    course
  end
end

IO.puts("\nCreating sample courses...")

# Elixir for Beginners
SeedHelper.insert_course(
  %{
    title: "Elixir for Beginners",
    description:
      "Learn the fundamentals of Elixir: pattern matching, recursion, OTP, and functional programming from the ground up."
  },
  [
    {1, "Introduction to Elixir", "BJRW5-oSCrE"},
    {2, "Pattern Matching", "D3FJHfBYOUU"},
    {3, "Functions and Modules", "R9lNNtJ_vm4"},
    {4, "Lists, Maps, and Tuples", "y38iWqN-75U"},
    {5, "Recursion and Tail Calls", "vV9C0oX2pXY"},
    {6, "Processes and Concurrency", "BJRW5-oSCrE"},
    {7, "GenServer Basics", "D3FJHfBYOUU"},
    {8, "Supervision Trees", "R9lNNtJ_vm4"}
  ]
)

# Phoenix LiveView Crash Course
SeedHelper.insert_course(
  %{
    title: "Phoenix LiveView Crash Course",
    description:
      "Build real-time reactive web apps with Phoenix LiveView — no JavaScript framework required, just Elixir all the way down."
  },
  [
    {1, "What is LiveView?", "R9lNNtJ_vm4"},
    {2, "Your First LiveView", "y38iWqN-75U"},
    {3, "Assigns and Rendering", "vV9C0oX2pXY"},
    {4, "Handling Events", "BJRW5-oSCrE"},
    {5, "LiveView Forms", "D3FJHfBYOUU"},
    {6, "PubSub and Real-Time Updates", "dQw4w9WgXcQ"},
    {7, "LiveComponents", "R9lNNtJ_vm4"},
    {8, "Streams and Large Lists", "y38iWqN-75U"},
    {9, "Deploying to Fly.io", "vV9C0oX2pXY"}
  ]
)

# Git & GitHub for Developers
SeedHelper.insert_course(
  %{
    title: "Git & GitHub for Developers",
    description:
      "Master Git version control and GitHub workflows: branching, merging, rebasing, pull requests, and team collaboration."
  },
  [
    {1, "Git Basics: Init, Add, Commit", "BJRW5-oSCrE"},
    {2, "Branching and Merging", "D3FJHfBYOUU"},
    {3, "Remote Repositories", "R9lNNtJ_vm4"},
    {4, "Pull Requests and Code Review", "y38iWqN-75U"},
    {5, "Rebasing and Conflict Resolution", "vV9C0oX2pXY"},
    {6, "Git Hooks and Automation", "dQw4w9WgXcQ"}
  ]
)

IO.puts("\nDone. Current courses:")

Repo.all(Course)
|> Enum.each(fn c ->
  count = Repo.aggregate(Ecto.Query.from(l in Lesson, where: l.course_id == ^c.id), :count)
  IO.puts("  [#{c.id}] #{c.title} — #{count} lessons")
end)
