defmodule Urielm.Forum.PostRevision do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "post_revisions" do
    field(:target_type, :string)
    field(:target_id, :binary_id)
    field(:body_before, :string)
    field(:body_after, :string)
    field(:title_before, :string)
    field(:title_after, :string)
    field(:revision_number, :integer)

    belongs_to(:editor, Urielm.Accounts.User, foreign_key: :editor_id, type: :id)

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  def changeset(revision, attrs) do
    revision
    |> cast(attrs, [
      :target_type,
      :target_id,
      :editor_id,
      :body_before,
      :body_after,
      :title_before,
      :title_after,
      :revision_number
    ])
    |> validate_required([
      :target_type,
      :target_id,
      :editor_id,
      :body_before,
      :body_after,
      :revision_number
    ])
    |> validate_inclusion(:target_type, ["thread", "comment"])
    |> foreign_key_constraint(:editor_id)
  end
end
