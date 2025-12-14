defmodule Urielm.Forum.ThreadTag do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "forum_thread_tags" do
    belongs_to(:thread, Urielm.Forum.Thread)
    belongs_to(:tag, Urielm.Forum.Tag)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(thread_tag, attrs) do
    thread_tag
    |> cast(attrs, [:thread_id, :tag_id])
    |> validate_required([:thread_id, :tag_id])
    |> foreign_key_constraint(:thread_id)
    |> foreign_key_constraint(:tag_id)
    |> unique_constraint([:thread_id, :tag_id])
  end
end
