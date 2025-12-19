defmodule Urielm.Repo.Migrations.AddCloseTimerToThreads do
  use Ecto.Migration

  def change do
    alter table(:forum_threads) do
      add :close_at, :utc_datetime_usec
      add :close_timer_set_by_id, references(:users, on_delete: :nilify_all)
    end

    create index(:forum_threads, [:close_at])
  end
end
