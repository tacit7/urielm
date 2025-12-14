defmodule Urielm.Repo.Migrations.CreateSubscriptionsAndNotifications do
  use Ecto.Migration

  def change do
    # Subscriptions - users can subscribe to threads
    create table(:forum_subscriptions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users), null: false
      add :thread_id, references(:forum_threads, type: :binary_id), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:forum_subscriptions, [:user_id, :thread_id])
    create index(:forum_subscriptions, [:user_id])

    # Notifications - in-app notifications for users
    create table(:forum_notifications, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users), null: false
      add :actor_id, references(:users)  # who triggered the notification
      add :subject_type, :string, null: false  # 'comment', 'reply', 'thread_update'
      add :subject_id, :binary_id, null: false
      add :thread_id, references(:forum_threads, type: :binary_id)
      add :message, :text
      add :read_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create index(:forum_notifications, [:user_id])
    create index(:forum_notifications, [:user_id, :read_at])
    create index(:forum_notifications, [:thread_id])
  end
end
