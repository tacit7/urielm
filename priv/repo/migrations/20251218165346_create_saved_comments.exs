defmodule Urielm.Repo.Migrations.CreateSavedComments do
  use Ecto.Migration

  def change do
    create table(:saved_comments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users), null: false
      add :comment_id, references(:forum_comments, type: :binary_id), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:saved_comments, [:user_id, :comment_id])
    create index(:saved_comments, [:user_id])
    create index(:saved_comments, [:comment_id])
  end
end
