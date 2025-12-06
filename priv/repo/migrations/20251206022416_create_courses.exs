defmodule Urielm.Repo.Migrations.CreateCourses do
  use Ecto.Migration

  def change do
    create table(:courses) do
      add :slug, :string, null: false
      add :title, :string, null: false
      add :description, :text
      add :youtube_playlist_id, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:courses, [:slug])
  end
end
