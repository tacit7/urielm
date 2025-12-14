defmodule Urielm.Forum.Tag do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "forum_tags" do
    field(:name, :string)
    field(:slug, :string)

    has_many(:thread_tags, Urielm.Forum.ThreadTag)
    has_many(:threads, through: [:thread_tags, :thread])

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name, :slug])
    |> validate_required([:name, :slug])
    |> validate_length(:name, min: 1, max: 50)
    |> validate_length(:slug, min: 1, max: 50)
    |> unique_constraint(:slug)
  end
end
