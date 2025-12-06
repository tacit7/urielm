defmodule Urielm.Learning do
  @moduledoc """
  The Learning context for managing courses and lessons.
  """

  import Ecto.Query, warn: false
  alias Urielm.Repo
  alias Urielm.Learning.{Course, Lesson}

  @doc """
  Returns the list of courses.
  """
  def list_courses do
    Repo.all(Course)
  end

  @doc """
  Gets a single course by ID.
  """
  def get_course!(id), do: Repo.get!(Course, id)

  @doc """
  Gets a single course by slug.
  """
  def get_course_by_slug(slug) do
    Repo.get_by(Course, slug: slug)
  end

  @doc """
  Creates a course.
  """
  def create_course(attrs \\ %{}) do
    %Course{}
    |> Course.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a course.
  """
  def update_course(%Course{} = course, attrs) do
    course
    |> Course.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a course.
  """
  def delete_course(%Course{} = course) do
    Repo.delete(course)
  end

  ## Lessons

  @doc """
  Returns the list of lessons for a course.
  """
  def list_lessons(course_id) do
    Lesson
    |> where([l], l.course_id == ^course_id)
    |> order_by([l], l.lesson_number)
    |> Repo.all()
  end

  @doc """
  Gets a single lesson by ID.
  """
  def get_lesson!(id), do: Repo.get!(Lesson, id)

  @doc """
  Gets a single lesson by course and slug.
  """
  def get_lesson_by_slug(course_id, slug) do
    Repo.get_by(Lesson, course_id: course_id, slug: slug)
  end

  @doc """
  Creates a lesson.
  """
  def create_lesson(attrs \\ %{}) do
    %Lesson{}
    |> Lesson.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a lesson.
  """
  def update_lesson(%Lesson{} = lesson, attrs) do
    lesson
    |> Lesson.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a lesson.
  """
  def delete_lesson(%Lesson{} = lesson) do
    Repo.delete(lesson)
  end
end
