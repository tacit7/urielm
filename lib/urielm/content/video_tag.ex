defmodule Urielm.Content.VideoTag do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "video_tags" do
    belongs_to(:video, Urielm.Content.Video)
    belongs_to(:tag, Urielm.Content.Tag, type: :id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(video_tag, attrs) do
    video_tag
    |> cast(attrs, [:video_id, :tag_id])
    |> validate_required([:video_id, :tag_id])
    |> foreign_key_constraint(:video_id)
    |> foreign_key_constraint(:tag_id)
    |> unique_constraint([:video_id, :tag_id])
  end
end
