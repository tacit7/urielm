defmodule Urielm.Repo.Migrations.CreateSavedPrompts do
  use Ecto.Migration

  def change do
    create table(:saved_prompts) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :prompt_id, references(:prompts, on_delete: :delete_all), null: false
      add :notes, :text
      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:saved_prompts, [:user_id, :prompt_id])
    create index(:saved_prompts, [:user_id])
    create index(:saved_prompts, [:prompt_id])
  end
end
