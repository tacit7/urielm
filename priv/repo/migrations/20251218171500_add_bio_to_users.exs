defmodule Urielm.Repo.Migrations.AddBioToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :bio, :text
      add :location, :string
      add :website, :string
    end
  end
end
