defmodule Urielm.Forum.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "forum_comments" do
    field(:body, :string)
    field(:score, :integer, default: 0)
    field(:is_removed, :boolean, default: false)

    belongs_to(:thread, Urielm.Forum.Thread)
    belongs_to(:author, Urielm.Accounts.User, type: :id)
    belongs_to(:parent, Urielm.Forum.Comment, foreign_key: :parent_id)
    belongs_to(:removed_by, Urielm.Accounts.User, foreign_key: :removed_by_id, type: :id)

    has_many(:replies, Urielm.Forum.Comment, foreign_key: :parent_id)
    has_many(:votes, Urielm.Forum.Vote, foreign_key: :target_id)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:thread_id, :author_id, :parent_id, :body, :is_removed, :removed_by_id])
    |> validate_required([:thread_id, :author_id, :body])
    |> foreign_key_constraint(:thread_id)
    |> foreign_key_constraint(:author_id)
    |> foreign_key_constraint(:parent_id)
    |> foreign_key_constraint(:removed_by_id)
  end
end
