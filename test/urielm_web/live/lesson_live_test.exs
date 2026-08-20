defmodule UrielmWeb.LessonLiveTest do
  use Urielm.DataCase

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Urielm.Learning

  @endpoint UrielmWeb.Endpoint

  use Phoenix.VerifiedRoutes,
    endpoint: UrielmWeb.Endpoint,
    router: UrielmWeb.Router,
    statics: UrielmWeb.static_paths()

  test "lesson viewer exposes its player, content navigation, and course outline" do
    {course, [first, lesson, third]} = course_with_lessons!()

    {:ok, view, _html} = live(build_conn(), ~p"/courses/#{course.slug}/lessons/#{lesson.slug}")

    assert has_element?(view, "#lesson-viewer")
    assert has_element?(view, "#lesson-player")
    assert has_element?(view, "#lesson-header")
    assert has_element?(view, "#lesson-section-nav")
    assert has_element?(view, "#lesson-content")
    assert has_element?(view, "#course-outline")
    assert has_element?(view, "#outline-lesson-#{lesson.id}[aria-current='page']")
    assert has_element?(view, "#lesson-mobile-dock")

    assert has_element?(
             view,
             "#previous-lesson-link[href='/courses/#{course.slug}/lessons/#{first.slug}']"
           )

    assert has_element?(
             view,
             "#next-lesson-link[href='/courses/#{course.slug}/lessons/#{third.slug}']"
           )
  end

  test "mobile lesson navigation switches the visible supporting section" do
    {course, [_first, lesson, _third]} = course_with_lessons!()

    {:ok, view, _html} = live(build_conn(), ~p"/courses/#{course.slug}/lessons/#{lesson.slug}")
    lesson_view = find_live_child(view, "page-lesson")

    lesson_view
    |> element("#lesson-mobile-notes")
    |> render_click()

    assert has_element?(lesson_view, "#lesson-notes:not(.hidden)")
    assert has_element?(lesson_view, "#lesson-mobile-notes.dock-active")
  end

  defp course_with_lessons! do
    suffix = System.unique_integer([:positive])

    {:ok, course} =
      Learning.create_course(%{
        title: "Practical Prompts #{suffix}",
        slug: "practical-prompts-#{suffix}",
        description: "Learn a repeatable process for writing prompts that are clear and testable."
      })

    lessons =
      for {number, title} <- [
            {1, "Define the outcome"},
            {2, "Add useful context"},
            {3, "Choose clear constraints"}
          ] do
        {:ok, lesson} =
          Learning.create_lesson(%{
            course_id: course.id,
            title: title,
            slug: "lesson-#{number}-#{suffix}",
            lesson_number: number,
            youtube_video_id: "dQw4w9WgXcQ",
            notes_md: "## Lesson notes\n\nA practical note for lesson #{number}.",
            resources_md: "- [Prompt guide](https://example.com)",
            timestamps_md: "00:00 Introduction"
          })

        lesson
      end

    {course, lessons}
  end
end
