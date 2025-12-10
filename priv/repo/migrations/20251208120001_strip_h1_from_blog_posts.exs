defmodule Urielm.Repo.Migrations.StripH1FromBlogPosts do
  use Ecto.Migration

  def up do
    execute("""
    UPDATE posts
    SET body = SUBSTRING(body FROM POSITION(E'\n' IN body) + 1)
    WHERE body LIKE '# %';
    """)
  end

  def down do
    # Cannot reliably restore removed H1 headings
    :ok
  end
end
