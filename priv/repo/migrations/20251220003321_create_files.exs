defmodule Urielm.Repo.Migrations.CreateFiles do
  use Ecto.Migration

  def change do
    create table(:files) do
      add :filename, :string, null: false
      add :content_type, :string, null: false
      add :size, :integer, null: false
      add :key, :string, null: false
      add :url, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :thread_id, references(:forum_threads, type: :binary_id, on_delete: :delete_all)
      add :comment_id, references(:forum_comments, type: :binary_id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:files, [:user_id])
    create index(:files, [:thread_id])
    create index(:files, [:comment_id])
    create unique_index(:files, [:key])
  end
end
