defmodule Urielm.Repo.Migrations.CreateUserFollows do
  use Ecto.Migration

  def change do
    create table(:user_follows, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :follower_id, references(:users, on_delete: :delete_all), null: false
      add :following_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:user_follows, [:follower_id, :following_id])
    create index(:user_follows, [:follower_id])
    create index(:user_follows, [:following_id])
  end
end
