defmodule Urielm.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :title, :string, null: false
      add :slug, :string, null: false
      add :body, :text, null: false
      add :excerpt, :text
      add :status, :string, null: false, default: "draft"
      add :published_at, :utc_datetime
      add :author_id, references(:users, on_delete: :nilify_all)

      timestamps()
    end

    create unique_index(:posts, [:slug])
    create index(:posts, [:status])
    create index(:posts, [:published_at])
  end
end
