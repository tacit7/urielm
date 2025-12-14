defmodule Urielm.Repo.Migrations.CreateForumTags do
  use Ecto.Migration

  def change do
    create table(:forum_tags, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :slug, :string, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:forum_tags, [:slug])

    create table(:forum_thread_tags, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :thread_id, references(:forum_threads, type: :binary_id), null: false
      add :tag_id, references(:forum_tags, type: :binary_id), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:forum_thread_tags, [:thread_id, :tag_id])
    create index(:forum_thread_tags, [:tag_id])
  end
end
