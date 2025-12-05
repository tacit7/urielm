defmodule Urielm.Content.Prompt do
  use Ecto.Schema
  import Ecto.Changeset

  schema "prompts" do
    field(:title, :string)
    field(:url, :string)
    field(:description, :string)
    field(:category, :string)
    field(:tags, {:array, :string})

    # Virtual field for search result ranking
    field(:rank, :float, virtual: true)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(prompt, attrs) do
    prompt
    |> cast(attrs, [:title, :url, :description, :category, :tags])
    |> validate_required([:title, :url, :category])
  end
end
