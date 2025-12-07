defmodule Urielm.Repo.Migrations.CreateLessonTopics do
  use Ecto.Migration

  def change do
    create table(:lesson_topics, primary_key: false) do
      add :lesson_id, references(:lessons, on_delete: :delete_all), null: false
      add :topic_id, references(:topics, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:lesson_topics, [:lesson_id, :topic_id])
    create index(:lesson_topics, [:topic_id])
  end
end
