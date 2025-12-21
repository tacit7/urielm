defmodule Urielm.Repo.Migrations.AddPaginationIndexes do
  use Ecto.Migration

  def change do
    # Composite indexes for forum_threads pagination queries
    # Supports: latest sort (updated_at DESC, id DESC)
    create index(:forum_threads, [:board_id, :is_removed, :updated_at, :id])

    # Supports: new sort (inserted_at DESC, id DESC)
    create index(:forum_threads, [:board_id, :is_removed, :inserted_at, :id])

    # Supports: top sort (score DESC, inserted_at DESC, id DESC)
    create index(:forum_threads, [:board_id, :is_removed, :score, :inserted_at, :id])

    # Supports: saved threads pagination (inserted_at DESC on saved_threads join)
    create index(:saved_threads, [:user_id, :inserted_at])

    # Note: Index on forum_topic_reads [:user_id, :thread_id] already exists
    # as a unique index from create_topic_reads migration
  end
end
