defmodule Urielm.Content.Prompt do
  use Ecto.Schema
  import Ecto.Changeset

  schema "prompts" do
    field(:title, :string)
    field(:url, :string)
    field(:description, :string)
    field(:category, :string)
    field(:tags, {:array, :string})

    # Counter fields
    field(:likes_count, :integer, default: 0)
    field(:comments_count, :integer, default: 0)
    field(:saves_count, :integer, default: 0)

    # Virtual field for search result ranking
    field(:rank, :float, virtual: true)

    # Associations
    has_many :comments, Urielm.Content.Comment
    has_many :likes, Urielm.Content.Like
    has_many :saved_prompts, Urielm.Accounts.SavedPrompt

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(prompt, attrs) do
    prompt
    |> cast(attrs, [:title, :url, :description, :category, :tags])
    |> validate_required([:title, :url, :category])
  end
end
