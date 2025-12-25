defmodule Urielm.Repo.Migrations.AddResourcesAndNotesToLessons do
  use Ecto.Migration

  def change do
    alter table(:lessons) do
      add :resources_md, :text
      add :timestamps_md, :text
    end

    # Rename body to notes_md for consistency with videos
    rename table(:lessons), :body, to: :notes_md
  end
end
