# Seeds for courses
alias Urielm.Learning

# ChatGPT for Beginners course
{:ok, chatgpt_course} = Learning.create_course(%{
  title: "ChatGPT for Beginners",
  description: "Learn how to use ChatGPT effectively from the ground up. Perfect for beginners who want to master AI-powered conversations.",
  youtube_playlist_id: "PLMWhJr00DBduSeEHb8TCm2wOV4ZoN4VDF"
})

IO.puts("Created course: #{chatgpt_course.title} (#{chatgpt_course.slug})")

# Lesson 1: What is ChatGPT
{:ok, lesson1} = Learning.create_lesson(%{
  course_id: chatgpt_course.id,
  title: "ChatGPT for Beginners: What is ChatGPT",
  body: "Small intro on what chat gpt is for people that want to learn what and how to use chagpt.",
  lesson_number: 1,
  youtube_video_id: "QxFk6W_4CzQ"
})

IO.puts("  - Lesson 1: #{lesson1.title} (#{lesson1.slug})")
