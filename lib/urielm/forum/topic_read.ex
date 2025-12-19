defmodule Urielm.Forum.TopicRead do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "forum_topic_reads" do
    field(:last_read_at, :utc_datetime_usec)

    belongs_to(:user, Urielm.Accounts.User, type: :id)
    belongs_to(:thread, Urielm.Forum.Thread)
    belongs_to(:last_comment, Urielm.Forum.Comment, type: :binary_id)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(topic_read, attrs) do
    topic_read
    |> cast(attrs, [:user_id, :thread_id, :last_read_at, :last_comment_id])
    |> validate_required([:user_id, :thread_id, :last_read_at])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:thread_id)
    |> foreign_key_constraint(:last_comment_id)
    |> unique_constraint([:user_id, :thread_id])
  end
end
