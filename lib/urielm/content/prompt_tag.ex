defmodule Urielm.Content.PromptTag do
  use Ecto.Schema
  import Ecto.Changeset

  schema "prompt_tags" do
    belongs_to(:prompt, Urielm.Content.Prompt)
    belongs_to(:tag, Urielm.Content.Tag)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(prompt_tag, attrs) do
    prompt_tag
    |> cast(attrs, [:prompt_id, :tag_id])
    |> validate_required([:prompt_id, :tag_id])
    |> unique_constraint([:prompt_id, :tag_id])
  end
end
