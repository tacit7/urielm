defmodule Urielm.Forum.Thread do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "forum_threads" do
    field(:title, :string)
    field(:slug, :string)
    field(:body, :string)
    field(:score, :integer, default: 0)
    field(:comment_count, :integer, default: 0)
    field(:is_locked, :boolean, default: false)
    field(:is_removed, :boolean, default: false)

    belongs_to(:board, Urielm.Forum.Board)
    belongs_to(:author, Urielm.Accounts.User, type: :id)
    belongs_to(:removed_by, Urielm.Accounts.User, foreign_key: :removed_by_id, type: :id)

    has_many(:comments, Urielm.Forum.Comment)
    has_many(:votes, Urielm.Forum.Vote, foreign_key: :target_id)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(thread, attrs) do
    thread
    |> cast(attrs, [
      :board_id,
      :author_id,
      :title,
      :slug,
      :body,
      :is_locked,
      :is_removed,
      :removed_by_id
    ])
    |> validate_required([:board_id, :author_id, :title, :slug, :body])
    |> foreign_key_constraint(:board_id)
    |> foreign_key_constraint(:author_id)
    |> foreign_key_constraint(:removed_by_id)
  end
end
