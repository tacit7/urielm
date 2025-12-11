defmodule Urielm.Repo.Migrations.CreateChatMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :body, :text, null: false
      add :user_id, references(:users, on_delete: :nilify_all)
      add :room_id, references(:rooms, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:messages, [:room_id])
    create index(:messages, [:user_id])
    create index(:messages, [:inserted_at])
  end
end
