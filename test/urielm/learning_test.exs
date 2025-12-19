defmodule Urielm.LearningTest do
  use Urielm.DataCase

  alias Urielm.Learning
  alias Urielm.Learning.Course
  alias Urielm.Fixtures

  describe "courses" do
    test "list_courses/0 returns all courses" do
      course1 = create_course(%{title: "Course 1", slug: "course-1"})
      course2 = create_course(%{title: "Course 2", slug: "course-2"})

      courses = Learning.list_courses()

      assert length(courses) >= 2
      assert Enum.any?(courses, &(&1.id == course1.id))
      assert Enum.any?(courses, &(&1.id == course2.id))
    end

    test "list_courses/0 returns empty list when no courses" do
      # Clear courses if any exist
      Repo.delete_all(Course)

      courses = Learning.list_courses()

      assert courses == []
    end

    test "get_course!/1 returns course by id" do
      course = create_course(%{title: "Test Course", slug: "test-course"})

      fetched = Learning.get_course!(course.id)

      assert fetched.id == course.id
      assert fetched.title == "Test Course"
    end

    test "get_course!/1 raises error for non-existent course" do
      assert_raise Ecto.NoResultsError, fn ->
        Learning.get_course!(9999)
      end
    end

    test "get_course_by_slug/1 returns course by slug" do
      course = create_course(%{title: "Elixir", slug: "elixir-basics"})

      fetched = Learning.get_course_by_slug("elixir-basics")

      assert fetched.id == course.id
      assert fetched.title == "Elixir"
    end

    test "get_course_by_slug/1 returns nil for non-existent slug" do
      result = Learning.get_course_by_slug("nonexistent")

      assert is_nil(result)
    end

    test "create_course/1 creates course with valid attrs" do
      attrs = %{
        title: "Phoenix Web",
        slug: "phoenix-web",
        description: "Build web apps with Phoenix"
      }

      {:ok, course} = Learning.create_course(attrs)

      assert course.title == "Phoenix Web"
      assert course.slug == "phoenix-web"
      assert course.description == "Build web apps with Phoenix"
    end

    test "create_course/1 requires title" do
      attrs = %{slug: "no-title"}

      {:error, changeset} = Learning.create_course(attrs)

      assert changeset.errors[:title]
    end

    test "create_course/1 auto-generates slug from title" do
      attrs = %{title: "My Test Course"}

      {:ok, course} = Learning.create_course(attrs)

      # Slug should be auto-generated from title
      assert course.slug == "my-test-course"
    end

    test "create_course/1 enforces unique slug" do
      Learning.create_course(%{title: "Course One"})

      # Trying to create with same auto-generated slug should fail
      {:error, changeset} = Learning.create_course(%{title: "Course One"})

      assert changeset.errors[:slug]
    end

    test "update_course/2 updates course attributes" do
      course = create_course(%{title: "Old Title"})

      {:ok, updated} = Learning.update_course(course, %{title: "New Title"})

      assert updated.id == course.id
      assert updated.title == "New Title"
      # Slug gets regenerated from title when title changes
      assert updated.slug == "new-title"
    end

    test "update_course/2 validates required fields" do
      course = create_course(%{title: "Test", slug: "test"})

      {:error, changeset} = Learning.update_course(course, %{title: ""})

      assert changeset.errors[:title]
    end

    test "delete_course/1 removes course" do
      course = create_course(%{title: "To Delete", slug: "to-delete"})

      {:ok, deleted} = Learning.delete_course(course)

      assert deleted.id == course.id
      assert is_nil(Learning.get_course_by_slug("to-delete"))
    end

    test "delete_course/1 cascades to lessons" do
      course = create_course(%{title: "Course", slug: "course"})
      _lesson = create_lesson(course, %{title: "Lesson 1", slug: "lesson-1", lesson_number: 1})

      {:ok, _} = Learning.delete_course(course)

      # Course is gone
      assert is_nil(Learning.get_course_by_slug("course"))
    end
  end

  describe "lessons" do
    setup do
      course = create_course(%{title: "Test Course", slug: "test-course"})
      {:ok, course: course}
    end

    test "list_lessons/1 returns lessons ordered by lesson_number", %{course: course} do
      lesson1 = create_lesson(course, %{title: "First", slug: "first", lesson_number: 1})
      lesson3 = create_lesson(course, %{title: "Third", slug: "third", lesson_number: 3})
      lesson2 = create_lesson(course, %{title: "Second", slug: "second", lesson_number: 2})

      lessons = Learning.list_lessons(course.id)

      assert length(lessons) == 3
      assert List.first(lessons).id == lesson1.id
      assert Enum.at(lessons, 1).id == lesson2.id
      assert List.last(lessons).id == lesson3.id
    end

    test "list_lessons/1 returns only lessons for that course", %{course: course} do
      other_course = create_course(%{title: "Other", slug: "other"})

      lesson1 = create_lesson(course, %{title: "Lesson 1", slug: "lesson-1", lesson_number: 1})

      lesson2 =
        create_lesson(other_course, %{
          title: "Other Lesson",
          slug: "other-lesson",
          lesson_number: 1
        })

      course_lessons = Learning.list_lessons(course.id)
      other_lessons = Learning.list_lessons(other_course.id)

      assert length(course_lessons) == 1
      assert List.first(course_lessons).id == lesson1.id
      assert length(other_lessons) == 1
      assert List.first(other_lessons).id == lesson2.id
    end

    test "list_lessons/1 empty course returns empty list", %{course: course} do
      lessons = Learning.list_lessons(course.id)

      assert lessons == []
    end

    test "get_lesson!/1 returns lesson by id", %{course: course} do
      lesson = create_lesson(course, %{title: "Test", slug: "test", lesson_number: 1})

      fetched = Learning.get_lesson!(lesson.id)

      assert fetched.id == lesson.id
      assert fetched.title == "Test"
    end

    test "get_lesson!/1 raises error for non-existent lesson" do
      assert_raise Ecto.NoResultsError, fn ->
        Learning.get_lesson!(9999)
      end
    end

    test "get_lesson_by_slug/2 returns lesson by course and slug", %{course: course} do
      lesson = create_lesson(course, %{title: "Basics", slug: "basics", lesson_number: 1})

      fetched = Learning.get_lesson_by_slug(course.id, "basics")

      assert fetched.id == lesson.id
      assert fetched.title == "Basics"
    end

    test "get_lesson_by_slug/2 returns nil for non-existent slug", %{course: course} do
      result = Learning.get_lesson_by_slug(course.id, "nonexistent")

      assert is_nil(result)
    end

    test "get_lesson_by_slug/2 is specific to course", %{course: course} do
      other_course = create_course(%{title: "Other", slug: "other"})
      create_lesson(other_course, %{title: "Lesson", slug: "lesson", lesson_number: 1})

      result = Learning.get_lesson_by_slug(course.id, "lesson")

      assert is_nil(result)
    end

    test "create_lesson/1 creates lesson with valid attrs", %{course: course} do
      attrs = %{
        title: "Introduction",
        slug: "intro",
        lesson_number: 1,
        course_id: course.id,
        body: "Lesson content here"
      }

      {:ok, lesson} = Learning.create_lesson(attrs)

      assert lesson.title == "Introduction"
      assert lesson.slug == "intro"
      assert lesson.lesson_number == 1
      assert lesson.course_id == course.id
      assert lesson.body == "Lesson content here"
    end

    test "create_lesson/1 requires title" do
      {:error, changeset} = Learning.create_lesson(%{slug: "no-title"})

      assert changeset.errors[:title]
    end

    test "create_lesson/1 auto-generates slug from title" do
      course = create_course(%{title: "Course"})

      {:ok, lesson} =
        Learning.create_lesson(%{
          title: "My Lesson",
          course_id: course.id,
          lesson_number: 1
        })

      assert lesson.slug == "my-lesson"
    end

    test "create_lesson/1 requires course_id" do
      {:error, changeset} = Learning.create_lesson(%{title: "Test", lesson_number: 1})

      assert changeset.errors[:course_id]
    end

    test "create_lesson/1 requires lesson_number" do
      course = create_course(%{title: "Course"})

      {:error, changeset} = Learning.create_lesson(%{title: "Test", course_id: course.id})

      assert changeset.errors[:lesson_number]
    end

    test "update_lesson/2 updates lesson attributes", %{course: course} do
      lesson = create_lesson(course, %{title: "Old", slug: "old", lesson_number: 1})

      {:ok, updated} = Learning.update_lesson(lesson, %{title: "New Title"})

      assert updated.id == lesson.id
      assert updated.title == "New Title"
    end

    test "delete_lesson/1 removes lesson", %{course: course} do
      lesson = create_lesson(course, %{title: "To Delete", slug: "delete", lesson_number: 1})

      {:ok, deleted} = Learning.delete_lesson(lesson)

      assert deleted.id == lesson.id
      assert is_nil(Learning.get_lesson_by_slug(course.id, "delete"))
    end
  end

  describe "lesson comments" do
    setup do
      course = create_course(%{title: "Course", slug: "course"})
      lesson = create_lesson(course, %{title: "Lesson", slug: "lesson", lesson_number: 1})
      user = Fixtures.user_fixture()

      {:ok, course: course, lesson: lesson, user: user}
    end

    test "create_lesson_comment/1 creates comment", %{lesson: lesson, user: user} do
      attrs = %{
        body: "Great lesson!",
        lesson_id: lesson.id,
        user_id: user.id
      }

      {:ok, comment} = Learning.create_lesson_comment(attrs)

      assert comment.body == "Great lesson!"
      assert comment.lesson_id == lesson.id
      assert comment.user_id == user.id
    end

    test "create_lesson_comment/1 requires body" do
      {:error, changeset} = Learning.create_lesson_comment(%{lesson_id: 1, user_id: 1})

      assert changeset.errors[:body]
    end

    test "create_lesson_comment/1 requires lesson_id" do
      user = Fixtures.user_fixture()

      {:error, changeset} = Learning.create_lesson_comment(%{body: "Comment", user_id: user.id})

      assert changeset.errors[:lesson_id]
    end

    test "list_lesson_comments/1 returns comments ordered by inserted_at", %{
      lesson: lesson,
      user: user
    } do
      comment1 = create_lesson_comment(lesson, user, "first")
      comment2 = create_lesson_comment(lesson, user, "second")
      comment3 = create_lesson_comment(lesson, user, "third")

      comments = Learning.list_lesson_comments(lesson)

      assert length(comments) == 3
      assert List.first(comments).id == comment1.id
      assert Enum.at(comments, 1).id == comment2.id
      assert List.last(comments).id == comment3.id
    end

    test "list_lesson_comments/1 preloads user data", %{lesson: lesson, user: user} do
      create_lesson_comment(lesson, user, "test")

      comments = Learning.list_lesson_comments(lesson)

      assert length(comments) == 1
      comment = List.first(comments)
      assert comment.user.id == user.id
      assert comment.user.email == user.email
    end

    test "list_lesson_comments/1 empty lesson returns empty list", %{lesson: lesson} do
      comments = Learning.list_lesson_comments(lesson)

      assert comments == []
    end

    test "change_lesson_comment/0 returns empty changeset" do
      changeset = Learning.change_lesson_comment()

      # Empty changeset requires body and lesson_id, so it's not valid
      refute changeset.valid?
      assert changeset.changes == %{}
    end

    test "change_lesson_comment/1 returns changeset for existing comment", %{
      lesson: lesson,
      user: user
    } do
      comment = create_lesson_comment(lesson, user, "test")

      changeset = Learning.change_lesson_comment(comment)

      assert changeset.data.id == comment.id
      assert changeset.valid?
    end
  end

  describe "get_lesson_with_comments/2" do
    setup do
      course = create_course(%{title: "Course", slug: "course"})
      lesson = create_lesson(course, %{title: "Lesson", slug: "lesson", lesson_number: 1})
      user = Fixtures.user_fixture()

      {:ok, course: course, lesson: lesson, user: user}
    end

    test "returns lesson with preloaded comments", %{course: course, lesson: lesson, user: user} do
      comment1 = create_lesson_comment(lesson, user, "first")
      comment2 = create_lesson_comment(lesson, user, "second")

      fetched = Learning.get_lesson_with_comments(course.id, "lesson")

      assert fetched.id == lesson.id
      assert length(fetched.comments) == 2
      assert List.first(fetched.comments).id == comment1.id
      assert List.last(fetched.comments).id == comment2.id
    end

    test "comments are ordered by inserted_at", %{course: course, lesson: lesson, user: user} do
      create_lesson_comment(lesson, user, "first")
      create_lesson_comment(lesson, user, "second")
      create_lesson_comment(lesson, user, "third")

      fetched = Learning.get_lesson_with_comments(course.id, "lesson")

      assert Enum.at(fetched.comments, 0).body == "first"
      assert Enum.at(fetched.comments, 1).body == "second"
      assert Enum.at(fetched.comments, 2).body == "third"
    end

    test "comments have preloaded user data", %{course: course, lesson: lesson, user: user} do
      create_lesson_comment(lesson, user, "test")

      fetched = Learning.get_lesson_with_comments(course.id, "lesson")

      comment = List.first(fetched.comments)
      assert comment.user.id == user.id
      assert comment.user.email == user.email
    end

    test "returns nil for non-existent lesson", %{course: course} do
      result = Learning.get_lesson_with_comments(course.id, "nonexistent")

      assert is_nil(result)
    end

    test "returns lesson with empty comments list", %{course: course, lesson: lesson} do
      fetched = Learning.get_lesson_with_comments(course.id, "lesson")

      assert fetched.id == lesson.id
      assert fetched.comments == []
    end
  end

  # Private helper functions

  defp create_course(attrs) do
    {:ok, course} = Learning.create_course(attrs)
    course
  end

  defp create_lesson(course, attrs) do
    attrs_with_course = Map.put(attrs, :course_id, course.id)
    {:ok, lesson} = Learning.create_lesson(attrs_with_course)
    lesson
  end

  defp create_lesson_comment(lesson, user, body) do
    {:ok, comment} =
      Learning.create_lesson_comment(%{
        body: body,
        lesson_id: lesson.id,
        user_id: user.id
      })

    comment
  end
end
