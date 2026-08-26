defmodule Urielm.Content.Video do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "videos" do
    field(:short_id, :integer, read_after_writes: true)
    field(:title, :string)
    field(:slug, :string)
    field(:youtube_url, :string)
    field(:tiktok_url, :string)
    field(:format, :string, default: "standard")
    field(:description_md, :string)
    field(:resources_md, :string)
    field(:author_name, :string)
    field(:author_url, :string)
    field(:author_bio_md, :string)
    field(:visibility, :string, default: "public")
    field(:published_at, :utc_datetime)

    belongs_to(:thread, Urielm.Forum.Thread, type: :binary_id)
    has_many(:video_completions, Urielm.Content.VideoCompletion)
    has_many(:video_tags, Urielm.Content.VideoTag)
    many_to_many(:tag_records, Urielm.Content.Tag, join_through: "video_tags")

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(video, attrs) do
    video
    |> cast(attrs, [
      :title,
      :slug,
      :youtube_url,
      :tiktok_url,
      :format,
      :description_md,
      :resources_md,
      :author_name,
      :author_url,
      :author_bio_md,
      :visibility,
      :published_at,
      :thread_id
    ])
    |> validate_required([:title, :slug, :visibility])
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/,
      message: "must contain only lowercase letters, numbers, and hyphens"
    )
    |> validate_inclusion(:visibility, ["public", "signed_in", "subscriber"])
    |> validate_inclusion(:format, ["standard", "short"])
    |> validate_video_url()
    |> unique_constraint(:slug, name: :videos_slug_index)
  end

  defp validate_video_url(changeset) do
    youtube = get_field(changeset, :youtube_url)
    tiktok = get_field(changeset, :tiktok_url)

    cond do
      youtube && youtube != "" ->
        validate_url(changeset, :youtube_url)

      tiktok && tiktok != "" ->
        validate_url(changeset, :tiktok_url)

      true ->
        add_error(changeset, :youtube_url, "either YouTube or TikTok URL is required")
    end
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
