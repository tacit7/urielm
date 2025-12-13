defmodule Urielm.Repo.Migrations.CreateForumTables do
  use Ecto.Migration

  def change do
    create table(:forum_categories, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :slug, :string, null: false
      add :position, :integer, default: 0
      add :is_hidden, :boolean, default: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:forum_categories, [:slug])

    create table(:forum_boards, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :category_id, references(:forum_categories, type: :binary_id), null: false
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :is_locked, :boolean, default: false
      add :is_hidden, :boolean, default: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:forum_boards, [:slug])
    create index(:forum_boards, [:category_id])

    create table(:forum_threads, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :board_id, references(:forum_boards, type: :binary_id), null: false
      add :author_id, references(:users), null: false
      add :title, :string, null: false
      add :slug, :string, null: false
      add :body, :text, null: false
      add :score, :integer, default: 0
      add :comment_count, :integer, default: 0
      add :is_locked, :boolean, default: false
      add :is_removed, :boolean, default: false
      add :removed_by_id, references(:users)

      timestamps(type: :utc_datetime_usec)
    end

    create index(:forum_threads, [:board_id, :inserted_at])
    create index(:forum_threads, [:board_id, :score])
    create index(:forum_threads, [:author_id])
    create index(:forum_threads, [:is_removed])

    create table(:forum_comments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :thread_id, references(:forum_threads, type: :binary_id), null: false
      add :author_id, references(:users), null: false
      add :parent_id, references(:forum_comments, type: :binary_id)
      add :body, :text, null: false
      add :score, :integer, default: 0
      add :is_removed, :boolean, default: false
      add :removed_by_id, references(:users)

      timestamps(type: :utc_datetime_usec)
    end

    create index(:forum_comments, [:thread_id, :parent_id, :inserted_at])
    create index(:forum_comments, [:author_id])
    create index(:forum_comments, [:parent_id])
    create index(:forum_comments, [:is_removed])

    create table(:forum_votes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users), null: false
      add :target_type, :string, null: false
      add :target_id, :binary_id, null: false
      add :value, :smallint, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:forum_votes, [:user_id, :target_type, :target_id])
    create index(:forum_votes, [:target_type, :target_id])
  end
end
