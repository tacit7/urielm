defmodule Urielm.Repo.Migrations.AddDescriptionAndSourceToPrompts do
  use Ecto.Migration

  def change do
    alter table(:prompts) do
      add :description, :text
      add :source, :text
    end
  end
end
