defmodule Urielm.Forum.Vote do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @valid_targets ["thread", "comment"]
  @valid_values [-1, 1]

  schema "forum_votes" do
    field(:target_type, :string)
    field(:target_id, :binary_id)
    field(:value, :integer)

    belongs_to(:user, Urielm.Accounts.User, type: :id)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(vote, attrs) do
    vote
    |> cast(attrs, [:user_id, :target_type, :target_id, :value])
    |> validate_required([:user_id, :target_type, :target_id, :value])
    |> validate_inclusion(:target_type, @valid_targets)
    |> validate_inclusion(:value, @valid_values)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:user_id, :target_type, :target_id],
      name: :forum_votes_user_id_target_type_target_id_index
    )
  end
end
