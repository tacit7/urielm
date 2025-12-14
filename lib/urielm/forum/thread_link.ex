defmodule Urielm.Forum.ThreadLink do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "forum_thread_links" do
    field(:link_type, :string)
    field(:link_id, :integer)

    belongs_to(:thread, Urielm.Forum.Thread)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(thread_link, attrs) do
    thread_link
    |> cast(attrs, [:thread_id, :link_type, :link_id])
    |> validate_required([:thread_id, :link_type, :link_id])
    |> validate_inclusion(:link_type, ["lesson", "course", "post"])
    |> foreign_key_constraint(:thread_id)
    |> unique_constraint([:link_type, :link_id])
  end
end
