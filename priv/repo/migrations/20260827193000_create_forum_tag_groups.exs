defmodule Urielm.Repo.Migrations.CreateForumTagGroups do
  use Ecto.Migration

  def change do
    create table(:forum_tag_groups, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :string

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:forum_tag_groups, ["lower(name)"],
             name: :forum_tag_groups_lower_name_index
           )

    create table(:forum_tag_group_memberships, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :tag_group_id,
          references(:forum_tag_groups, type: :binary_id, on_delete: :delete_all),
          null: false

      add :tag_id, references(:forum_tags, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:forum_tag_group_memberships, [:tag_group_id, :tag_id])
    create unique_index(:forum_tag_group_memberships, [:tag_id])
  end
end
