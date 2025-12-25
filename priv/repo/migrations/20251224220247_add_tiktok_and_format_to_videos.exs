defmodule Urielm.Repo.Migrations.AddTiktokAndFormatToVideos do
  use Ecto.Migration

  def change do
    alter table(:videos) do
      add :tiktok_url, :string
      add :format, :string, default: "standard"
    end

    # Make youtube_url nullable for TikTok-only videos
    execute "ALTER TABLE videos ALTER COLUMN youtube_url DROP NOT NULL",
            "ALTER TABLE videos ALTER COLUMN youtube_url SET NOT NULL"
  end
end
