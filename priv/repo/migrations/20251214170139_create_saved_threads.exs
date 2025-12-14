defmodule Urielm.Repo.Migrations.CreateSavedThreads do
  use Ecto.Migration

  def change do
    create table(:saved_threads, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users), null: false
      add :thread_id, references(:forum_threads, type: :binary_id), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:saved_threads, [:user_id, :thread_id])
    create index(:saved_threads, [:user_id])
    create index(:saved_threads, [:thread_id])
  end
end
