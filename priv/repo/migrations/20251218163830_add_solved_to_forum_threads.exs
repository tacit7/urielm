defmodule Urielm.Repo.Migrations.AddSolvedToForumThreads do
  use Ecto.Migration

  def change do
    alter table(:forum_threads) do
      add :is_solved, :boolean, default: false, null: false
      add :solved_comment_id, references(:forum_comments, type: :binary_id, on_delete: :nilify_all)
      add :solved_at, :utc_datetime_usec
      add :solved_by_id, references(:users, on_delete: :nilify_all)
    end

    create index(:forum_threads, [:is_solved])
    create index(:forum_threads, [:solved_comment_id])
  end
end
