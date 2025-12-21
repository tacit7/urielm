defmodule Urielm.Repo.Migrations.CreateVideos do
  use Ecto.Migration

  def change do
    create table(:videos, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :slug, :string, null: false
      add :youtube_url, :text, null: false
      add :description_md, :text, default: ""
      add :resources_md, :text, default: ""
      add :author_name, :string
      add :author_url, :string
      add :author_bio_md, :text, default: ""
      add :visibility, :string, null: false, default: "public"
      add :published_at, :utc_datetime
      add :thread_id, references(:forum_threads, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:videos, [:slug])

    create constraint(:videos, :visibility_must_be_valid,
      check: "visibility IN ('public', 'signed_in', 'subscriber')"
    )
  end
end
