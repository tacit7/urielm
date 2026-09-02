defmodule Urielm.Repo.Migrations.AddCapabilityBadgeSettingsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:capability_badge_settings, :map, default: %{}, null: false)
    end
  end
end
