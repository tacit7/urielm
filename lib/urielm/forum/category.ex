defmodule Urielm.Forum.Category do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "forum_categories" do
    field(:name, :string)
    field(:slug, :string)
    field(:position, :integer, default: 0)
    field(:is_hidden, :boolean, default: false)

    has_many(:boards, Urielm.Forum.Board)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :slug, :position, :is_hidden])
    |> validate_required([:name, :slug])
    |> unique_constraint(:slug)
  end
end
