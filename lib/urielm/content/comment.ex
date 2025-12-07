defmodule Urielm.Content.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "comments" do
    field(:body, :string)
    field(:edited_at, :utc_datetime)
    field(:deleted_at, :utc_datetime)

    belongs_to(:user, Urielm.Accounts.User)
    belongs_to(:prompt, Urielm.Content.Prompt)
    belongs_to(:parent, __MODULE__)
    has_many(:replies, __MODULE__, foreign_key: :parent_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:body, :user_id, :prompt_id, :parent_id, :edited_at, :deleted_at])
    |> validate_required([:body, :user_id, :prompt_id])
    |> validate_length(:body, min: 1, max: 10_000)
  end
end
