defmodule Urielm.Repo.Migrations.CreateLikes do
  use Ecto.Migration

  def change do
    create table(:likes) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :prompt_id, references(:prompts, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:likes, [:user_id, :prompt_id])
    create index(:likes, [:user_id])
    create index(:likes, [:prompt_id])
  end
end
