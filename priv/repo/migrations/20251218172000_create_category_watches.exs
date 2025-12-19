defmodule Urielm.Repo.Migrations.CreateCategoryWatches do
  use Ecto.Migration

  def change do
    create table(:category_watches, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :category_id, references(:forum_categories, type: :binary_id, on_delete: :delete_all), null: false
      add :watch_level, :string, null: false, default: "normal"
      # watch_level: watching | tracking | normal | muted

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:category_watches, [:user_id, :category_id])
    create index(:category_watches, [:user_id])
    create index(:category_watches, [:category_id])
  end
end
