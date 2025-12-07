defmodule Urielm.Accounts.SavedPrompt do
  use Ecto.Schema
  import Ecto.Changeset

  schema "saved_prompts" do
    field(:notes, :string)

    belongs_to(:user, Urielm.Accounts.User)
    belongs_to(:prompt, Urielm.Content.Prompt)

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc false
  def changeset(saved_prompt, attrs) do
    saved_prompt
    |> cast(attrs, [:user_id, :prompt_id, :notes])
    |> validate_required([:user_id, :prompt_id])
    |> unique_constraint([:user_id, :prompt_id])
  end
end
