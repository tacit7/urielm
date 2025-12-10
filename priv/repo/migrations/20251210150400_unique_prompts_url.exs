defmodule Urielm.Repo.Migrations.UniquePromptsUrl do
  use Ecto.Migration

  def change do
    create unique_index(:prompts, [:url], where: "url IS NOT NULL")
  end
end
