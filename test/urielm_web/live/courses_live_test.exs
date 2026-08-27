defmodule UrielmWeb.CoursesLiveTest do
  use Urielm.DataCase

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Urielm.Learning

  @endpoint UrielmWeb.Endpoint

  use Phoenix.VerifiedRoutes,
    endpoint: UrielmWeb.Endpoint,
    router: UrielmWeb.Router,
    statics: UrielmWeb.static_paths()

  test "courses index uses the shared page hierarchy and stable collection" do
    {course, _lesson} = course_with_lesson!()

    {:ok, view, _html} = live(build_conn(), ~p"/courses")

    assert has_element?(view, "#courses-index")
    assert has_element?(view, "#courses-index-header")
    assert has_element?(view, "#courses-collection")
    assert has_element?(view, "#featured-course-#{course.id}")
  end

  test "courses index uses the shared empty state" do
    {:ok, view, _html} = live(build_conn(), ~p"/courses")

    assert has_element?(view, "#courses-empty-state[data-ui-state='empty']")
  end

  test "course detail exposes its hero, description, and lesson collection" do
    {course, lesson} = course_with_lesson!()

    {:ok, view, _html} = live(build_conn(), ~p"/courses/#{course.slug}")

    assert has_element?(view, "#course-detail")
    assert has_element?(view, "#course-detail-hero")
    assert has_element?(view, "#course-description")
    assert has_element?(view, "#course-lessons")
    assert has_element?(view, "#lesson-#{lesson.id}")
  end

  test "course detail uses the shared empty state when lessons are unavailable" do
    suffix = System.unique_integer([:positive])

    {:ok, course} =
      Learning.create_course(%{
        title: "Upcoming AI #{suffix}",
        slug: "upcoming-ai-#{suffix}",
        description: "A course outline awaiting its first lesson."
      })

    {:ok, view, _html} = live(build_conn(), ~p"/courses/#{course.slug}")

    assert has_element?(view, "#course-lessons-empty[data-ui-state='empty']")
    refute has_element?(view, "#course-lessons-list")
  end

  defp course_with_lesson! do
    suffix = System.unique_integer([:positive])

    {:ok, course} =
      Learning.create_course(%{
        title: "Practical AI #{suffix}",
        slug: "practical-ai-#{suffix}",
        description: "Build reliable AI applications through a focused learning path."
      })

    {:ok, lesson} =
      Learning.create_lesson(%{
        course_id: course.id,
        title: "Start with a clear goal",
        slug: "clear-goal",
        lesson_number: 1,
        youtube_video_id: "dQw4w9WgXcQ",
        notes_md: "Learn how clear outcomes improve every prompt."
      })

    {course, lesson}
  end
end
