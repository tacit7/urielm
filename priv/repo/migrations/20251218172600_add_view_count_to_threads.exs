defmodule Urielm.Repo.Migrations.AddViewCountToThreads do
  use Ecto.Migration

  def change do
    alter table(:forum_threads) do
      add :view_count, :integer, default: 0, null: false
    end

    create index(:forum_threads, [:view_count])
  end
end
