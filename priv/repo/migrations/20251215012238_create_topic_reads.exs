defmodule Urielm.Repo.Migrations.CreateTopicReads do
  use Ecto.Migration

  def change do
    # Track when each user last read each topic
    create table(:forum_topic_reads, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users), null: false
      add :thread_id, references(:forum_threads, type: :binary_id), null: false
      add :last_read_at, :utc_datetime_usec, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:forum_topic_reads, [:user_id, :thread_id])
    create index(:forum_topic_reads, [:user_id])
    create index(:forum_topic_reads, [:user_id, :last_read_at])
  end
end
