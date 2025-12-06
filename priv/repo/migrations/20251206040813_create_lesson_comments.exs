defmodule Urielm.Repo.Migrations.CreateLessonComments do
  use Ecto.Migration

  def change do
    create table(:lesson_comments) do
      add :body, :text, null: false

      add :lesson_id,
        references(:lessons, on_delete: :delete_all),
        null: false

      add :user_id,
        references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:lesson_comments, [:lesson_id])
    create index(:lesson_comments, [:user_id])
  end
end
