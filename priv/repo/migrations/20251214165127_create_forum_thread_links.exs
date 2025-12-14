defmodule Urielm.Repo.Migrations.CreateForumThreadLinks do
  use Ecto.Migration

  def change do
    create table(:forum_thread_links, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :thread_id, references(:forum_threads, type: :binary_id), null: false
      add :link_type, :string, null: false  # 'lesson' | 'course' | 'post'
      add :link_id, :integer, null: false  # lesson_id, course_id, or post_id

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:forum_thread_links, [:link_type, :link_id])
    create index(:forum_thread_links, [:thread_id])
  end
end
