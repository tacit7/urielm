defmodule Urielm.Repo.Migrations.AddKindToForumThreads do
  use Ecto.Migration

  def change do
    alter table(:forum_threads) do
      add :kind, :string, null: false, default: "forum"
    end

    create constraint(:forum_threads, :kind_must_be_valid,
      check: "kind IN ('forum', 'video')"
    )

    create index(:forum_threads, [:kind])
  end
end
