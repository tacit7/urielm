defmodule Urielm.Repo.Migrations.AddProcessStatusToPrompts do
  use Ecto.Migration

  def change do
    alter table(:prompts) do
      add :process_status, :string, default: "pending"
    end

    create index(:prompts, [:process_status])
  end
end

