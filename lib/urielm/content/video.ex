defmodule Urielm.Content.Video do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "videos" do
    field :short_id, :integer, read_after_writes: true
    field :title, :string
    field :slug, :string
    field :youtube_url, :string
    field :description_md, :string
    field :resources_md, :string
    field :author_name, :string
    field :author_url, :string
    field :author_bio_md, :string
    field :visibility, :string, default: "public"
    field :published_at, :utc_datetime

    belongs_to :thread, Urielm.Forum.Thread, type: :binary_id
    has_many :video_completions, Urielm.Content.VideoCompletion

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(video, attrs) do
    video
    |> cast(attrs, [
      :title,
      :slug,
      :youtube_url,
      :description_md,
      :resources_md,
      :author_name,
      :author_url,
      :author_bio_md,
      :visibility,
      :published_at,
      :thread_id
    ])
    |> validate_required([:title, :slug, :youtube_url, :visibility])
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/, message: "must contain only lowercase letters, numbers, and hyphens")
    |> validate_url(:youtube_url)
    |> validate_inclusion(:visibility, ["public", "signed_in", "subscriber"])
    |> unique_constraint(:slug, name: :videos_slug_key)
  end

  defp validate_url(changeset, field) do
    validate_change(changeset, field, fn _, url ->
      uri = URI.parse(url)

      if uri.scheme in ["http", "https"] and uri.host do
        []
      else
        [{field, "must be a valid URL"}]
      end
    end)
  end
end
