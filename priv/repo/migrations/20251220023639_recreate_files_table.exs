defmodule Urielm.Repo.Migrations.RecreateFilesTable do
  use Ecto.Migration

  def change do
    # Drop existing table
    drop_if_exists table(:files)

    # Create new table with polymorphic associations
    create table(:files, primary_key: false) do
      add :id, :uuid, primary_key: true  # UUID v7
      add :entity_type, :text, null: false
      add :entity_id, :uuid, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      # Storage metadata
      add :storage_key, :text, null: false
      add :original_filename, :text, null: false
      add :content_type, :text, null: false
      add :byte_size, :bigint, null: false

      # Optional metadata
      add :visibility, :text, default: "public", null: false
      add :checksum_sha256, :bytea
      add :width, :integer
      add :height, :integer
      add :deleted_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    # Indexes
    create index(:files, [:entity_type, :entity_id])
    create index(:files, [:user_id])
    create index(:files, [:deleted_at], where: "deleted_at IS NOT NULL")
    create unique_index(:files, [:storage_key])

    # Constraints
    execute """
    ALTER TABLE files
    ADD CONSTRAINT visibility_check
    CHECK (visibility IN ('public', 'private', 'participants'))
    """, ""
  end
end
