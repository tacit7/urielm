defmodule Urielm.Repo.Migrations.RenameReferencesToPrompts do
  use Ecto.Migration

  def up do
    # Use raw SQL because "references" is a reserved keyword
    execute "ALTER TABLE \"references\" RENAME TO prompts"
    execute "ALTER SEQUENCE references_id_seq RENAME TO prompts_id_seq"
  end

  def down do
    execute "ALTER TABLE prompts RENAME TO \"references\""
    execute "ALTER SEQUENCE prompts_id_seq RENAME TO references_id_seq"
  end
end
