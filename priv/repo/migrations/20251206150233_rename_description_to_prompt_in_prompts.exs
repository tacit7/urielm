defmodule Urielm.Repo.Migrations.RenameDescriptionToPromptInPrompts do
  use Ecto.Migration

  def change do
    rename table(:prompts), :description, to: :prompt
  end
end
