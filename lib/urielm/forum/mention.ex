defmodule Urielm.Forum.Mention do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "mentions" do
    belongs_to(:user, Urielm.Accounts.User, type: :id)
    belongs_to(:mentioner, Urielm.Accounts.User, foreign_key: :mentioner_id, type: :id)
    field(:target_type, :string)
    field(:target_id, :binary_id)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(mention, attrs) do
    mention
    |> cast(attrs, [:user_id, :mentioner_id, :target_type, :target_id])
    |> validate_required([:user_id, :mentioner_id, :target_type, :target_id])
    |> validate_inclusion(:target_type, ["thread", "comment"])
    |> unique_constraint([:user_id, :target_type, :target_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:mentioner_id)
  end
end
