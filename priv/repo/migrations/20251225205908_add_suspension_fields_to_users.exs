defmodule Urielm.Repo.Migrations.AddSuspensionFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      # Suspension (cannot login)
      add :suspended_at, :utc_datetime, default: nil
      add :suspended_until, :utc_datetime, default: nil
      add :suspended_reason, :text, default: nil

      # Silencing (can read, cannot post)
      add :silenced_at, :utc_datetime, default: nil
      add :silenced_until, :utc_datetime, default: nil
      add :silenced_reason, :text, default: nil
    end

    # Index for checking active suspensions/silencing
    create index(:users, [:suspended_at], where: "suspended_at IS NOT NULL")
    create index(:users, [:silenced_at], where: "silenced_at IS NOT NULL")
  end
end
