defmodule Urielm.Repo.Migrations.AddHeroImageToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :hero_image, :string
    end

    # Optional: if you want to query posts that have a hero image quickly
    # create index(:posts, [:hero_image])
  end
end

