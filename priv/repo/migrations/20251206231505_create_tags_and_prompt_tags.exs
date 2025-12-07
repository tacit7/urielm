defmodule Urielm.Repo.Migrations.CreateTagsAndPromptTags do
  use Ecto.Migration

  def change do
    # Create tags table
    create table(:tags) do
      add :name, :string, null: false
      add :slug, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:tags, [:slug])

    # Create join table for many-to-many relationship
    create table(:prompt_tags) do
      add :prompt_id, references(:prompts, on_delete: :delete_all), null: false
      add :tag_id, references(:tags, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:prompt_tags, [:prompt_id])
    create index(:prompt_tags, [:tag_id])
    create unique_index(:prompt_tags, [:prompt_id, :tag_id])

    # Add processed field to prompts
    alter table(:prompts) do
      add :processed, :boolean, default: false
    end
  end
end
