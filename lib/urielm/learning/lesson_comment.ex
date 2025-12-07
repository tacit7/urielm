defmodule Urielm.Learning.LessonComment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "lesson_comments" do
    field(:body, :string)

    belongs_to(:lesson, Urielm.Learning.Lesson)
    belongs_to(:user, Urielm.Accounts.User)

    timestamps(type: :utc_datetime)
  end

  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:body, :lesson_id, :user_id])
    |> validate_required([:body, :lesson_id])
    |> validate_length(:body, min: 3, max: 2000)
  end
end
