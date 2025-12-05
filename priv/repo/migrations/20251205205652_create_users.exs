defmodule Urielm.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :name, :string
      add :avatar_url, :string
      add :email_verified, :boolean, default: false
      add :active, :boolean, default: true
      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
  end
end
