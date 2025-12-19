defmodule Urielm.Repo.Migrations.CreateMentions do
  use Ecto.Migration

  def change do
    create table(:mentions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :mentioner_id, references(:users, on_delete: :delete_all), null: false
      add :target_type, :string, null: false # "thread" | "comment"
      add :target_id, :binary_id, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:mentions, [:user_id])
    create index(:mentions, [:target_type, :target_id])
    create unique_index(:mentions, [:user_id, :target_type, :target_id])
  end
end
