defmodule Urielm.Repo.Migrations.AddLastCommentToTopicReads do
  use Ecto.Migration

  def change do
    alter table(:forum_topic_reads) do
      add :last_comment_id, references(:forum_comments, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:forum_topic_reads, [:last_comment_id])
  end
end
