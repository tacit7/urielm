defmodule Urielm.Learning.Lesson do
  use Ecto.Schema
  import Ecto.Changeset

  schema "lessons" do
    field(:slug, :string)
    field(:title, :string)
    field(:body, :string)
    field(:lesson_number, :integer)
    field(:youtube_video_id, :string)

    belongs_to(:course, Urielm.Learning.Course)
    has_many(:comments, Urielm.Learning.LessonComment)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(lesson, attrs) do
    lesson
    |> cast(attrs, [:course_id, :title, :slug, :body, :lesson_number, :youtube_video_id])
    |> validate_required([:course_id, :title, :lesson_number])
    |> unique_constraint([:course_id, :slug])
    |> unique_constraint([:course_id, :lesson_number])
    |> maybe_generate_slug()
  end

  defp maybe_generate_slug(changeset) do
    case get_change(changeset, :slug) do
      nil ->
        case get_change(changeset, :title) do
          nil -> changeset
          title -> put_change(changeset, :slug, slugify(title))
        end

      _slug ->
        changeset
    end
  end

  defp slugify(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/\s+/, "-")
    |> String.trim("-")
  end
end
