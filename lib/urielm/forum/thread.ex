defmodule Urielm.Forum.Thread do
  use Ecto.Schema
  import Ecto.Changeset
  # use Flop.Schema
  @derive {Flop.Schema,
           filterable: [],
           sortable: [:id, :title, :inserted_at, :updated_at, :score, :author_id, :board_id]}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "forum_threads" do
    field(:title, :string)
    field(:slug, :string)
    field(:body, :string)
    field(:kind, :string, default: "forum")
    field(:score, :integer, default: 0)
    field(:comment_count, :integer, default: 0)
    field(:view_count, :integer, default: 0)
    field(:is_locked, :boolean, default: false)
    field(:is_removed, :boolean, default: false)
    field(:is_solved, :boolean, default: false)
    field(:is_pinned, :boolean, default: false)
    field(:edited_at, :utc_datetime_usec)
    field(:solved_at, :utc_datetime_usec)
    field(:pinned_at, :utc_datetime_usec)
    field(:close_at, :utc_datetime_usec)

    belongs_to(:board, Urielm.Forum.Board)
    belongs_to(:author, Urielm.Accounts.User, type: :id)
    belongs_to(:removed_by, Urielm.Accounts.User, foreign_key: :removed_by_id, type: :id)
    belongs_to(:solved_comment, Urielm.Forum.Comment, type: :binary_id)
    belongs_to(:solved_by, Urielm.Accounts.User, foreign_key: :solved_by_id, type: :id)
    belongs_to(:pinned_by, Urielm.Accounts.User, foreign_key: :pinned_by_id, type: :id)

    belongs_to(:close_timer_set_by, Urielm.Accounts.User,
      foreign_key: :close_timer_set_by_id,
      type: :id
    )

    has_many(:comments, Urielm.Forum.Comment)
    has_many(:votes, Urielm.Forum.Vote, foreign_key: :target_id)

    timestamps(type: :utc_datetime_usec)
  end

  # @impl true
  # def flop_fields do
  #   [
  #     name: :title,
  #     inserted_at: true,
  #     updated_at: true,
  #     score: true,
  #     author_id: true,
  #     board_id: true
  #   ]
  # end

  @doc false
  def changeset(thread, attrs) do
    thread
    |> cast(attrs, [
      :board_id,
      :author_id,
      :title,
      :slug,
      :body,
      :kind,
      :is_locked,
      :is_removed,
      :removed_by_id,
      :edited_at,
      :is_solved,
      :solved_comment_id,
      :solved_at,
      :solved_by_id,
      :is_pinned,
      :pinned_at,
      :pinned_by_id
    ])
    |> validate_required([:board_id, :author_id, :title, :slug, :body])
    |> validate_inclusion(:kind, ["forum", "video"])
    |> validate_length(:title, min: 3, max: 300)
    |> validate_length(:body, min: 10, max: 10000)
    |> sanitize_body()
    |> foreign_key_constraint(:board_id)
    |> foreign_key_constraint(:author_id)
    |> foreign_key_constraint(:removed_by_id)
    |> foreign_key_constraint(:solved_comment_id)
    |> foreign_key_constraint(:solved_by_id)
  end

  defp sanitize_body(changeset) do
    # For now, just trim whitespace
    # Full sanitization/XSS prevention can be added later with html_sanitize_ex
    update_change(changeset, :body, &String.trim/1)
  end
end
