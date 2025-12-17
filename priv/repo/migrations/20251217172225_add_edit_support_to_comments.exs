defmodule Urielm.Repo.Migrations.AddEditSupportToComments do
  use Ecto.Migration

  def change do
    alter table(:forum_comments) do
      add :edited_at, :timestamp, null: true
    end

    alter table(:forum_threads) do
      add :edited_at, :timestamp, null: true
    end
  end
end
