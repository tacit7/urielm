defmodule Urielm.Repo.Migrations.CreateTopicNotificationSettings do
  use Ecto.Migration

  def change do
    create table(:forum_topic_notification_settings, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, :id, null: false
      add :thread_id, :binary_id, null: false
      add :notification_level, :string, null: false, default: "watching"
      # watching, tracking, muted

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:forum_topic_notification_settings, [:user_id, :thread_id])
    create index(:forum_topic_notification_settings, [:user_id])
    create index(:forum_topic_notification_settings, [:thread_id])
  end
end
