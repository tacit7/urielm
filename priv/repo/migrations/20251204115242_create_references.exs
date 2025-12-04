defmodule Urielm.Repo.Migrations.CreateReferences do
  use Ecto.Migration

  def change do
    create table(:references) do
      add :title, :string
      add :url, :string
      add :description, :text
      add :category, :string
      add :tags, {:array, :string}

      timestamps(type: :utc_datetime)
    end
  end
end
