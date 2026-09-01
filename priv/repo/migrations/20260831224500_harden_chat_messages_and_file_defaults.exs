defmodule Urielm.Repo.Migrations.HardenChatMessagesAndFileDefaults do
  use Ecto.Migration

  def up do
    execute "DELETE FROM messages WHERE user_id IS NULL"

    execute "ALTER TABLE messages DROP CONSTRAINT IF EXISTS messages_user_id_fkey"

    alter table(:messages) do
      modify :user_id, references(:users, on_delete: :delete_all), null: false
    end

    alter table(:files) do
      modify :visibility, :text, default: "participants", null: false
    end
  end

  def down do
    alter table(:files) do
      modify :visibility, :text, default: "public", null: false
    end

    execute "ALTER TABLE messages DROP CONSTRAINT IF EXISTS messages_user_id_fkey"

    alter table(:messages) do
      modify :user_id, references(:users, on_delete: :nilify_all), null: true
    end
  end
end
