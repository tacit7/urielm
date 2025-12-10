defmodule Urielm.Content.Prompt do
  use Ecto.Schema
  import Ecto.Changeset

  schema "prompts" do
    field(:title, :string)
    field(:url, :string)
    field(:prompt, :string)
    field(:description, :string)
    field(:source, :string)
    field(:category, :string)
    field(:processed, :boolean, default: false)

    # Counter fields
    field(:likes_count, :integer, default: 0)
    field(:comments_count, :integer, default: 0)
    field(:saves_count, :integer, default: 0)

    # Virtual field for search result ranking
    field(:rank, :float, virtual: true)

    # Associations
    has_many(:comments, Urielm.Content.Comment)
    has_many(:likes, Urielm.Content.Like)
    has_many(:saved_prompts, Urielm.Accounts.SavedPrompt)
    many_to_many(:tag_records, Urielm.Content.Tag, join_through: "prompt_tags")

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(prompt, attrs) do
    prompt
    |> cast(attrs, [:title, :url, :prompt, :description, :source, :category, :processed])
    |> validate_required([:title, :category])
  end
end
