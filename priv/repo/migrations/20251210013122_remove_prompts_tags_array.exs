defmodule UrielM.Repo.Migrations.RemovePromptsTagsArray do
  use Ecto.Migration

  def change do
    alter table(:prompts) do
      remove :tags, {:array, :string}
    end
  end
end
