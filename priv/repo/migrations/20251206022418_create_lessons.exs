defmodule Urielm.Repo.Migrations.CreateLessons do
  use Ecto.Migration

  def change do
    create table(:lessons) do
      add :course_id, references(:courses, on_delete: :delete_all), null: false

      add :slug, :string, null: false
      add :title, :string, null: false
      add :body, :text
      add :lesson_number, :integer, null: false

      add :youtube_video_id, :string

      timestamps(type: :utc_datetime)
    end

    # one course cannot have two lessons with the same slug
    create unique_index(:lessons, [:course_id, :slug])

    # enforce ordering uniqueness inside a course
    create unique_index(:lessons, [:course_id, :lesson_number])

    # common filter index
    create index(:lessons, [:course_id])
  end
end
