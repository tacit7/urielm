defmodule Urielm.Repo.Migrations.AddIsAdminToUsers do
  use Ecto.Migration

  def up do
    # Only add the column if it doesn't already exist
    execute """
    ALTER TABLE users
    ADD COLUMN IF NOT EXISTS is_admin boolean NOT NULL DEFAULT false
    """
  end

  def down do
    alter table(:users) do
      remove :is_admin
    end
  end
end
