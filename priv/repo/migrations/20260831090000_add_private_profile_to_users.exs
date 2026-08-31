defmodule Urielm.Repo.Migrations.AddPrivateProfileToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:private_profile, :boolean, default: false, null: false)
    end
  end
end
