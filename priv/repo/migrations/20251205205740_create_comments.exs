defmodule Urielm.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :user_id, references(:users, on_delete: :nilify_all), null: false
      add :prompt_id, references(:prompts, on_delete: :delete_all), null: false
      add :parent_id, references(:comments, on_delete: :delete_all)
      add :body, :text, null: false
      add :edited_at, :utc_datetime
      add :deleted_at, :utc_datetime
      timestamps(type: :utc_datetime)
    end

    create index(:comments, [:prompt_id])
    create index(:comments, [:parent_id])
    create index(:comments, [:user_id])
  end
end
