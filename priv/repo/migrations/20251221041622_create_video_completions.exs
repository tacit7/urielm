defmodule Urielm.Repo.Migrations.CreateVideoCompletions do
  use Ecto.Migration

  def change do
    create table(:video_completions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :video_id, references(:videos, type: :binary_id, on_delete: :delete_all), null: false
      add :completed_at, :utc_datetime, null: false
    end

    create unique_index(:video_completions, [:user_id, :video_id])
  end
end
