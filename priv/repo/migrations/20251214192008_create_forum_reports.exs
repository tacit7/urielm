defmodule Urielm.Repo.Migrations.CreateForumReports do
  use Ecto.Migration

  def change do
    create table(:forum_reports, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users), null: false
      add :target_type, :string, null: false  # 'thread' | 'comment'
      add :target_id, :binary_id, null: false
      add :reason, :string, null: false  # 'spam' | 'abuse' | 'offensive' | 'other'
      add :description, :text
      add :status, :string, default: "pending", null: false  # 'pending' | 'reviewed' | 'resolved' | 'dismissed'
      add :reviewed_by_id, references(:users)
      add :resolved_at, :utc_datetime_usec
      add :resolution_notes, :text

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:forum_reports, [:user_id, :target_type, :target_id])
    create index(:forum_reports, [:status])
    create index(:forum_reports, [:target_type, :target_id])
    create index(:forum_reports, [:user_id])
  end
end
