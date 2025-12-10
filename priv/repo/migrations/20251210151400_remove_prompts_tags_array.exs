defmodule Urielm.Repo.Migrations.RemovePromptsTagsArray do
  use Ecto.Migration

  def change do
    alter table(:prompts) do
      # reversible because we specify the type
      remove :tags, {:array, :string}
    end
  end
end
