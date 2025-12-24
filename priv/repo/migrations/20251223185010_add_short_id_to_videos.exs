defmodule Urielm.Repo.Migrations.AddShortIdToVideos do
  use Ecto.Migration

  def change do
    # Add short_id column with serial (auto-increment)
    alter table(:videos) do
      add :short_id, :serial
    end

    create unique_index(:videos, [:short_id])
  end
end
