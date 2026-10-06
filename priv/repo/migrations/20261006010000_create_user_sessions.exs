defmodule Urielm.Repo.Migrations.CreateUserSessions do
  use Ecto.Migration

  def change do
    create table(:user_sessions) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token_hash, :binary, null: false
      add :credential_hash, :binary, null: false
      add :context, :string, null: false
      add :expires_at, :utc_datetime, null: false
      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:user_sessions, [:token_hash])
    create index(:user_sessions, [:user_id])
    create index(:user_sessions, [:expires_at])
  end
end
