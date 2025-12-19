defmodule Urielm.Repo.Migrations.AddIsModeratorToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :is_moderator, :boolean, default: false, null: false
    end

    create index(:users, [:is_moderator])
  end
end
