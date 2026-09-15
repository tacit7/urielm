defmodule UrielmWeb.LessonLiveTest do
  use Urielm.DataCase

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import Urielm.Fixtures, only: [user_fixture: 0]

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
    assert has_element?(view, "#lesson-player[data-ui-component='learning-media-player']")
    assert has_element?(view, "#lesson-header")

    assert has_element?(
             view,
             "#lesson-section-nav[data-ui-component='learning-media-tabs']"
           )

    assert has_element?(view, "#lesson-content")
    assert has_element?(view, "#course-outline")
    assert has_element?(view, "#outline-lesson-#{lesson.id}[aria-current='page']")
    assert has_element?(view, "#lesson-sign-in-to-comment.alert-info")

    assert has_element?(
             view,
             "#lesson-mobile-dock[data-navigation='lesson-dock'][aria-label='Lesson sections']"
           )

    assert has_element?(
             view,
             "#previous-lesson-link[href='/courses/#{course.slug}/lessons/#{first.slug}']"
           )

    assert has_element?(
             view,
             "#next-lesson-link[href='/courses/#{course.slug}/lessons/#{third.slug}']"
           )
  end

  test "initial HTTP response includes lesson content and crawlable resource links" do
    {course, [_first, lesson, _third]} = course_with_lessons!()

    document =
      build_conn()
      |> get(~p"/courses/#{course.slug}/lessons/#{lesson.slug}")
      |> html_response(200)
      |> LazyHTML.from_document()

    assert document |> LazyHTML.query("#lesson-header h1") |> LazyHTML.text() =~ lesson.title

    assert document |> LazyHTML.query("#lesson-notes") |> LazyHTML.text() =~
             "A practical note for lesson 2."

    assert document
           |> LazyHTML.query("#lesson-resources a")
           |> LazyHTML.attribute("href") == ["https://example.com"]

    assert document |> LazyHTML.query("#lesson-timestamps") |> LazyHTML.text() =~
             "00:00 Introduction"
  end

  test "lesson Markdown renders tables and strikethrough in initial and connected HTML" do
    {course, [_first, lesson, _third]} = course_with_lessons!()

    {:ok, lesson} =
      Learning.update_lesson(lesson, %{
        notes_md: markdown_with_table_and_strikethrough("Notes"),
        resources_md: markdown_with_table_and_strikethrough("Resources"),
        timestamps_md: markdown_with_table_and_strikethrough("Timestamps")
      })

    initial_document =
      build_conn()
      |> get(~p"/courses/#{course.slug}/lessons/#{lesson.slug}")
      |> html_response(200)
      |> LazyHTML.from_document()

    assert_rendered_markdown_extensions(initial_document)

    {:ok, view, _html} = live(build_conn(), ~p"/courses/#{course.slug}/lessons/#{lesson.slug}")

    connected_document =
      view
      |> find_live_child("page-lesson")
      |> render()
      |> LazyHTML.from_fragment()

    assert_rendered_markdown_extensions(connected_document)
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

  test "shared lesson tabs switch the desktop supporting section" do
    {course, [_first, lesson, _third]} = course_with_lessons!()

    {:ok, view, _html} = live(build_conn(), ~p"/courses/#{course.slug}/lessons/#{lesson.slug}")
    lesson_view = find_live_child(view, "page-lesson")

    lesson_view
    |> element("#lesson-tab-comments")
    |> render_click()

    assert has_element?(lesson_view, "#lesson-tab-comments[aria-current='page']")
    assert has_element?(lesson_view, "#lesson-comments[class*='lg:block']")
  end

  test "posting a comment refreshes the lesson and tab count" do
    user = user_fixture()
    {course, [_first, lesson, _third]} = course_with_lessons!()

    conn = UrielmWeb.ConnCase.log_in_user(build_conn(), user)
    {:ok, view, _html} = live(conn, ~p"/courses/#{course.slug}/lessons/#{lesson.slug}")
    lesson_view = find_live_child(view, "page-lesson")

    lesson_view
    |> element("#lesson-tab-comments")
    |> render_click()

    lesson_view
    |> form("#lesson-comment-form", %{comment: %{body: "A useful observation"}})
    |> render_submit()

    assert [%{body: "A useful observation"}] = Learning.list_lesson_comments(lesson)
    assert has_element?(lesson_view, "#lesson-tab-comments", "1")
    assert has_element?(lesson_view, "#lesson-comment-list [id^='lesson-comment-']")
    assert has_element?(lesson_view, "#lesson-comment-submit")
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

  defp markdown_with_table_and_strikethrough(label) do
    """
    | Section | Status |
    | --- | --- |
    | #{label} | ~~outdated~~ |
    """
  end

  defp assert_rendered_markdown_extensions(document) do
    for section_id <- ["lesson-notes", "lesson-resources", "lesson-timestamps"] do
      section = LazyHTML.query(document, "##{section_id}")

      refute section |> LazyHTML.query("table") |> Enum.empty?()
      assert section |> LazyHTML.query("del") |> LazyHTML.text() =~ "outdated"
      refute section |> LazyHTML.text() =~ "~~outdated~~"
    end
  end
end
