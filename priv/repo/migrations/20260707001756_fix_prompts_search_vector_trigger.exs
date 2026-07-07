defmodule Urielm.Repo.Migrations.FixPromptsSearchVectorTrigger do
  use Ecto.Migration

  def up do
    # The tags array column was removed in remove_prompts_tags_array but the trigger
    # function still referenced NEW.tags, causing ERROR 42703 on any prompt insert.
    execute """
    CREATE OR REPLACE FUNCTION prompts_search_vector_update() RETURNS trigger AS $$
    BEGIN
      NEW.search_vector :=
        setweight(coalesce(to_tsvector('simple', NEW.title), ''), 'A') ||
        setweight(coalesce(to_tsvector('simple', NEW.category), ''), 'B') ||
        setweight(coalesce(to_tsvector('simple', coalesce(NEW.description, '')), ''), 'D');
      RETURN NEW;
    END
    $$ LANGUAGE plpgsql IMMUTABLE;
    """
  end

  def down do
    # Restore original function (will fail on insert if tags column absent)
    execute """
    CREATE OR REPLACE FUNCTION prompts_search_vector_update() RETURNS trigger AS $$
    BEGIN
      NEW.search_vector :=
        setweight(coalesce(to_tsvector('simple', NEW.title), ''), 'A') ||
        setweight(coalesce(to_tsvector('simple', NEW.category), ''), 'B') ||
        setweight(coalesce(to_tsvector('simple', array_to_string(NEW.tags, ' ')), ''), 'C') ||
        setweight(coalesce(to_tsvector('simple', coalesce(NEW.description, '')), ''), 'D');
      RETURN NEW;
    END
    $$ LANGUAGE plpgsql IMMUTABLE;
    """
  end
end
