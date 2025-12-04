defmodule Urielm.Repo.Migrations.AddSearchToPrompts do
  use Ecto.Migration

  def up do
    # Enable pg_trgm extension for fuzzy search
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm"

    # Add search_vector column (nullable initially)
    alter table(:prompts) do
      add :search_vector, :tsvector
    end

    # Create function to update search_vector
    execute """
    CREATE OR REPLACE FUNCTION prompts_search_vector_update() RETURNS trigger AS $$
    BEGIN
      NEW.search_vector :=
        setweight(coalesce(to_tsvector('simple', NEW.title), ''), 'A') ||
        setweight(coalesce(to_tsvector('simple', NEW.category), ''), 'B') ||
        setweight(coalesce(to_tsvector('simple', array_to_string(NEW.tags, ' ')), ''), 'C') ||
        setweight(coalesce(to_tsvector('simple', NEW.description), ''), 'D');
      RETURN NEW;
    END
    $$ LANGUAGE plpgsql IMMUTABLE;
    """

    # Create trigger to automatically update search_vector
    execute """
    CREATE TRIGGER prompts_search_vector_trigger
    BEFORE INSERT OR UPDATE ON prompts
    FOR EACH ROW
    EXECUTE FUNCTION prompts_search_vector_update();
    """

    # Update existing rows
    execute """
    UPDATE prompts SET search_vector =
      setweight(coalesce(to_tsvector('simple', title), ''), 'A') ||
      setweight(coalesce(to_tsvector('simple', category), ''), 'B') ||
      setweight(coalesce(to_tsvector('simple', array_to_string(tags, ' ')), ''), 'C') ||
      setweight(coalesce(to_tsvector('simple', description), ''), 'D')
    """

    # Add GIN index for full-text search
    create index(:prompts, [:search_vector], using: :gin, name: :idx_prompts_search_vector)

    # Add index on category for filtering
    create index(:prompts, [:category], name: :idx_prompts_category)

    # Add GIN index on title for trigram similarity (fuzzy search)
    execute "CREATE INDEX idx_prompts_title_trgm ON prompts USING GIN (title gin_trgm_ops)"
  end

  def down do
    # Drop trigger and function
    execute "DROP TRIGGER IF EXISTS prompts_search_vector_trigger ON prompts"
    execute "DROP FUNCTION IF EXISTS prompts_search_vector_update()"

    # Drop indexes
    drop index(:prompts, [:search_vector], name: :idx_prompts_search_vector)
    drop index(:prompts, [:category], name: :idx_prompts_category)
    execute "DROP INDEX IF EXISTS idx_prompts_title_trgm"

    # Drop column
    alter table(:prompts) do
      remove :search_vector
    end

    # Drop extension
    execute "DROP EXTENSION IF EXISTS pg_trgm"
  end
end
