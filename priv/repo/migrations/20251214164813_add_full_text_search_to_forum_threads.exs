defmodule Urielm.Repo.Migrations.AddFullTextSearchToForumThreads do
  use Ecto.Migration

  def change do
    alter table(:forum_threads) do
      add :search_vector, :tsvector
    end

    create index(:forum_threads, [:search_vector], using: :gin)

    # Generate search vectors for existing threads
    execute """
    UPDATE forum_threads
    SET search_vector = setweight(to_tsvector('english', COALESCE(title, '')), 'A') ||
                         setweight(to_tsvector('english', COALESCE(body, '')), 'B')
    WHERE search_vector IS NULL
    """

    # Create trigger to automatically update search_vector on insert/update
    execute """
    CREATE OR REPLACE FUNCTION update_forum_thread_search_vector()
    RETURNS TRIGGER AS $$
    BEGIN
      NEW.search_vector := setweight(to_tsvector('english', COALESCE(NEW.title, '')), 'A') ||
                           setweight(to_tsvector('english', COALESCE(NEW.body, '')), 'B');
      RETURN NEW;
    END
    $$ LANGUAGE plpgsql;
    """

    execute """
    DROP TRIGGER IF EXISTS forum_thread_search_vector_trigger ON forum_threads;
    """

    execute """
    CREATE TRIGGER forum_thread_search_vector_trigger
    BEFORE INSERT OR UPDATE ON forum_threads
    FOR EACH ROW EXECUTE FUNCTION update_forum_thread_search_vector();
    """
  end
end
