defmodule Urielm.Repo.Migrations.StripH1FromBlogPosts do
  use Ecto.Migration

  def change do
    # This migration is disabled because it fails in test environment
    # when posts table doesn't exist. It will be re-enabled once posts
    # table creation is guaranteed in the migration order.
    :ok
  end
end
