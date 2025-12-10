defmodule Urielm.Repo.Migrations.AddHeroImageToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :hero_image, :string
    end
  end
end
