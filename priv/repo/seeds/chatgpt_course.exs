alias Urielm.Learning

# Create the course
{:ok, course} = Learning.create_course(%{
  title: "ChatGPT for Beginners",
  description: "Learn how to use ChatGPT effectively from the ground up. Perfect for beginners who want to master AI-powered conversations.",
  youtube_playlist_id: "PLy9mLEnHHo4XLPIgN0NQkY8rcqw-eMutg"
})

IO.puts("Created course: #{course.title} (#{course.slug})")

lessons = [
  {"What is ChatGPT?", "BJRW5-oSCrE"},
  {"How to Use ChatGPT", "D3FJHfBYOUU"},
  {"ChatGPT Prompt Engineering for Beginners", "9L9fN_1T93E"},
  {"How to Use ChatGPT for Excel & Google Sheets", "y38iWqN-75U"},
  {"How to Use ChatGPT for Data Analysis", "vV9C0oX2pXY"},
  {"How to Use ChatGPT for Writing & Content Creation", "M6X9uY3f7iE"},
  {"How to Use ChatGPT to Learn Anything Faster", "W_n3L_V3L-g"},
  {"How to Use ChatGPT for Coding", "uD9O5_0fS98"},
  {"ChatGPT Plus vs Free: Is it Worth it?", "qT-VnE9-2G8"},
  {"How to Use ChatGPT Custom Instructions", "f9vW6NfB9eY"},
  {"How to Use ChatGPT GPTs (The GPT Store)", "vV7X3n8X_vY"},
  {"How to Use ChatGPT Vision", "v7O8_X8B_qU"},
  {"How to Use ChatGPT Voice Mode", "v8O9_X9B_rV"},
  {"How to Use ChatGPT Canvas for Writing and Coding", "v9O10_X10B_s"},
  {"ChatGPT Search vs Google: Which is Better?", "v11O11_X11B_t"}
]

Enum.with_index(lessons, 1)
|> Enum.each(fn {{title, video_id}, num} ->
  {:ok, lesson} = Learning.create_lesson(%{
    course_id: course.id,
    title: title,
    lesson_number: num,
    youtube_video_id: video_id
  })
  IO.puts("  #{num}. #{lesson.title}")
end)

IO.puts("\nDone! Course available at /courses/#{course.slug}")
