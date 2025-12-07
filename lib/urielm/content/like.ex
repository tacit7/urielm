defmodule Urielm.Content.Like do
  use Ecto.Schema
  import Ecto.Changeset

  schema "likes" do
    belongs_to(:user, Urielm.Accounts.User)
    belongs_to(:prompt, Urielm.Content.Prompt)

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc false
  def changeset(like, attrs) do
    like
    |> cast(attrs, [:user_id, :prompt_id])
    |> validate_required([:user_id, :prompt_id])
    |> unique_constraint([:user_id, :prompt_id])
  end
end
