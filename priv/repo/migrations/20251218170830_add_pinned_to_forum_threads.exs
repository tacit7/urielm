defmodule Urielm.Repo.Migrations.AddPinnedToForumThreads do
  use Ecto.Migration

  def change do
    alter table(:forum_threads) do
      add :is_pinned, :boolean, default: false, null: false
      add :pinned_at, :utc_datetime_usec
      add :pinned_by_id, references(:users, on_delete: :nilify_all)
    end

    create index(:forum_threads, [:is_pinned])
    create index(:forum_threads, [:board_id, :is_pinned, :inserted_at])
  end
end
