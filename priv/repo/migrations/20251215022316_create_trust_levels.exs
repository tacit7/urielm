defmodule Urielm.Repo.Migrations.CreateTrustLevels do
  use Ecto.Migration

  def change do
    # User trust levels (0-4)
    alter table(:users) do
      add :trust_level, :integer, default: 0, null: false
      add :trust_level_locked, :boolean, default: false
    end

    # Trust level configuration (admin-editable thresholds and permissions)
    create table(:trust_level_configs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :level, :integer, null: false  # 0-4
      add :name, :string, null: false    # "New", "Basic", "Member", "Regular", "Leader"
      add :color, :string, null: false   # for UI badges

      # Thresholds to auto-promote to this level
      add :min_topics, :integer, default: 0
      add :min_posts, :integer, default: 0
      add :min_days_joined, :integer, default: 0
      add :min_likes_given, :integer, default: 0
      add :min_likes_received, :integer, default: 0

      # Rate limiting
      add :max_posts_per_minute, :integer, null: false
      add :max_new_topics_per_day, :integer, null: false

      # Permissions (JSON for flexibility)
      add :permissions, :jsonb, default: "{}"

      # Edit window in minutes (-1 = unlimited)
      add :post_edit_time_limit, :integer, default: 5

      # Can pin topics, manage categories, etc
      add :can_pin_topics, :boolean, default: false
      add :can_feature_topics, :boolean, default: false
      add :can_close_topics, :boolean, default: false
      add :can_moderate, :boolean, default: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:trust_level_configs, [:level])
  end
end
