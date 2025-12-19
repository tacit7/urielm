defmodule Urielm.Repo.Migrations.CreatePostRevisions do
  use Ecto.Migration

  def change do
    create table(:post_revisions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :target_type, :string, null: false # "thread" | "comment"
      add :target_id, :binary_id, null: false
      add :editor_id, references(:users, on_delete: :nilify_all), null: false
      add :body_before, :text, null: false
      add :body_after, :text, null: false
      add :title_before, :string # Only for threads
      add :title_after, :string  # Only for threads
      add :revision_number, :integer, null: false

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create index(:post_revisions, [:target_type, :target_id, :inserted_at])
    create index(:post_revisions, [:editor_id])
  end
end
