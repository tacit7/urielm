defmodule Urielm.Forum.SavedComment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "saved_comments" do
    belongs_to(:user, Urielm.Accounts.User, type: :id)
    belongs_to(:comment, Urielm.Forum.Comment)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(saved_comment, attrs) do
    saved_comment
    |> cast(attrs, [:user_id, :comment_id])
    |> validate_required([:user_id, :comment_id])
    |> unique_constraint([:user_id, :comment_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:comment_id)
  end
end
