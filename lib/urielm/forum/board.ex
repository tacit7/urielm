defmodule Urielm.Forum.Board do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "forum_boards" do
    field(:name, :string)
    field(:slug, :string)
    field(:description, :string)
    field(:is_locked, :boolean, default: false)
    field(:is_hidden, :boolean, default: false)
    field(:thread_count, :integer, virtual: true, default: 0)
    field(:post_count, :integer, virtual: true, default: 0)
    field(:last_activity_at, :utc_datetime_usec, virtual: true)
    field(:latest_thread_title, :string, virtual: true)
    field(:latest_thread_slug, :string, virtual: true)

    belongs_to(:category, Urielm.Forum.Category)
    has_many(:threads, Urielm.Forum.Thread)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(board, attrs) do
    board
    |> cast(attrs, [:category_id, :name, :slug, :description, :is_locked, :is_hidden])
    |> validate_required([:category_id, :name, :slug])
    |> unique_constraint(:slug)
    |> foreign_key_constraint(:category_id)
  end
end
