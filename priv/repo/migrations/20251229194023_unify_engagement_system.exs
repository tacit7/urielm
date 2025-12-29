defmodule Urielm.Repo.Migrations.UnifyEngagementSystem do
  use Ecto.Migration

  def change do
    # 1. Rename forum_votes to votes (already has the right shape)
    rename table(:forum_votes), to: table(:votes)

    # Rename indexes to match new table name
    execute "ALTER INDEX forum_votes_pkey RENAME TO votes_pkey",
            "ALTER INDEX votes_pkey RENAME TO forum_votes_pkey"

    execute "ALTER INDEX forum_votes_user_id_target_type_target_id_index RENAME TO votes_user_id_target_type_target_id_index",
            "ALTER INDEX votes_user_id_target_type_target_id_index RENAME TO forum_votes_user_id_target_type_target_id_index"

    execute "ALTER INDEX forum_votes_target_type_target_id_index RENAME TO votes_target_type_target_id_index",
            "ALTER INDEX votes_target_type_target_id_index RENAME TO forum_votes_target_type_target_id_index"

    # Rename foreign key constraint
    execute "ALTER TABLE votes RENAME CONSTRAINT forum_votes_user_id_fkey TO votes_user_id_fkey",
            "ALTER TABLE votes RENAME CONSTRAINT votes_user_id_fkey TO forum_votes_user_id_fkey"

    # Add check constraint for value (-1 or 1)
    create constraint(:votes, :votes_value_check, check: "value IN (-1, 1)")

    # 2. Drop likes table (only 2 rows, not worth migrating)
    drop table(:likes)

    # 3. Create discussions mapping table
    create table(:discussions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :target_type, :string, null: false
      add :target_id, :bigint, null: false
      add :thread_id, references(:forum_threads, type: :binary_id, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:discussions, [:target_type, :target_id])
    create unique_index(:discussions, [:thread_id])
  end
end
