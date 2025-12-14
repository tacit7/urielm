# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Urielm.Repo.insert!(%Urielm.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong and you can
# catch the error in your shell.

alias Urielm.Repo
alias Urielm.Learning

# Example: Create a course with lessons
# Uncomment and modify as needed

# Course: ChatGPT for Beginners
course_attrs = %{
  "title" => "ChatGPT for Beginners",
  "slug" => "chatgpt-for-beginners",
  "description" => "Learn the fundamentals of ChatGPT and how to use it effectively.",
  "youtube_playlist_id" => "PLxxxxxxxxxxxxxx"
}

case Learning.get_course_by_slug("chatgpt-for-beginners") do
  nil ->
    {:ok, course} = Learning.create_course(course_attrs)
    
    # Add lessons to the course
    lessons = [
      %{
        "title" => "What is ChatGPT",
        "slug" => "what-is-chatgpt",
        "lesson_number" => 1,
        "youtube_video_id" => "QxFk6W_4CzQ",
        "body" => "Introduction to ChatGPT, what it is, and how it works."
      },
      %{
        "title" => "Getting Started",
        "slug" => "getting-started",
        "lesson_number" => 2,
        "youtube_video_id" => "YOUR_VIDEO_ID_HERE",
        "body" => "How to sign up and start using ChatGPT."
      },
      %{
        "title" => "Advanced Prompting",
        "slug" => "advanced-prompting",
        "lesson_number" => 3,
        "youtube_video_id" => "YOUR_VIDEO_ID_HERE",
        "body" => "Techniques for writing effective prompts."
      }
    ]
    
    Enum.each(lessons, fn lesson_attrs ->
      Learning.create_lesson(course.id, lesson_attrs)
    end)
    
    IO.puts("✓ Created course '#{course.title}' with #{length(lessons)} lessons")

  course ->
    IO.puts("Course already exists: #{course.title}")
end

# Add more courses as needed below...
