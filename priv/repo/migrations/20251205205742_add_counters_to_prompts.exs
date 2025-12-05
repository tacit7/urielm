defmodule Urielm.Repo.Migrations.AddCountersToPrompts do
  use Ecto.Migration

  def change do
    alter table(:prompts) do
      add :likes_count, :integer, default: 0
      add :comments_count, :integer, default: 0
      add :saves_count, :integer, default: 0
    end

    create index(:prompts, [:likes_count])
  end
end
