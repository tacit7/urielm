defmodule Urielm.Learning.Course do
  use Ecto.Schema
  import Ecto.Changeset

  schema "courses" do
    field :slug, :string
    field :title, :string
    field :description, :string
    field :youtube_playlist_id, :string

    has_many :lessons, Urielm.Learning.Lesson

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(course, attrs) do
    course
    |> cast(attrs, [:title, :slug, :description, :youtube_playlist_id])
    |> validate_required([:title])
    |> maybe_generate_slug()
    |> validate_required([:slug])
    |> unique_constraint(:slug)
  end

  defp maybe_generate_slug(changeset) do
    case get_change(changeset, :slug) do
      nil ->
        case get_change(changeset, :title) do
          nil -> changeset
          title -> put_change(changeset, :slug, slugify(title))
        end
      _slug -> changeset
    end
  end

  defp slugify(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/\s+/, "-")
    |> String.trim("-")
  end
end
