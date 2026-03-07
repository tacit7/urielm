defmodule Urielm.Repo.Migrations.ChangeVotesTargetIdToText do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE votes ALTER COLUMN target_id TYPE text USING target_id::text"
  end

  def down do
    execute "ALTER TABLE votes ALTER COLUMN target_id TYPE uuid USING target_id::uuid"
  end
end
