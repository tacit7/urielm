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
    |> validate_length(:title, min: 3, max: 300)
    |> validate_length(:body, min: 10, max: 10000)
    |> sanitize_body()
    |> foreign_key_constraint(:board_id)
    |> foreign_key_constraint(:author_id)
    |> foreign_key_constraint(:removed_by_id)
  end

  defp sanitize_body(changeset) do
    # For now, just trim whitespace
    # Full sanitization/XSS prevention can be added later with html_sanitize_ex
    update_change(changeset, :body, &String.trim/1)
  end
end
