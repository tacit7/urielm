defmodule Urielm.Forum.TagGroup do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "forum_tag_groups" do
    field(:name, :string)
    field(:description, :string)
    field(:tag_ids, {:array, :binary_id}, virtual: true, default: [])

    has_many(:memberships, Urielm.Forum.TagGroupMembership)

    many_to_many(:tags, Urielm.Forum.Tag,
      join_through: Urielm.Forum.TagGroupMembership,
      join_keys: [tag_group_id: :id, tag_id: :id]
    )

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(tag_group, attrs) do
    tag_group
    |> cast(attrs, [:name, :description, :tag_ids])
    |> update_change(:name, &String.trim/1)
    |> update_change(:description, &normalize_description/1)
    |> validate_required([:name])
    |> validate_length(:name, max: 100)
    |> validate_length(:description, max: 500)
    |> unique_constraint(:name, name: :forum_tag_groups_lower_name_index)
  end

  defp normalize_description(nil), do: nil

  defp normalize_description(description) do
    case String.trim(description) do
      "" -> nil
      trimmed -> trimmed
    end
  end
end
