defmodule Urielm.Repo.Migrations.CreateSubscriptions do
  use Ecto.Migration

  def change do
    create table(:subscriptions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :status, :string, null: false, default: "active"
      add :current_period_end, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:subscriptions, [:user_id])

    create constraint(:subscriptions, :status_must_be_valid,
      check: "status IN ('active', 'canceled', 'past_due')"
    )
  end
end
