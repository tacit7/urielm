defmodule Urielm.Forum.TagGroupMembership do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "forum_tag_group_memberships" do
    belongs_to(:tag_group, Urielm.Forum.TagGroup)
    belongs_to(:tag, Urielm.Forum.Tag)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:tag_group_id, :tag_id])
    |> validate_required([:tag_group_id, :tag_id])
    |> foreign_key_constraint(:tag_group_id)
    |> foreign_key_constraint(:tag_id)
    |> unique_constraint([:tag_group_id, :tag_id])
    |> unique_constraint(:tag_id)
  end
end
