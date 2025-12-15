defmodule Urielm.Forum.Report do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "forum_reports" do
    field(:target_type, :string)
    field(:target_id, :binary_id)
    field(:reason, :string)
    field(:description, :string)
    field(:status, :string, default: "pending")
    field(:resolved_at, :utc_datetime_usec)
    field(:resolution_notes, :string)

    belongs_to(:user, Urielm.Accounts.User, type: :id)
    belongs_to(:reviewed_by, Urielm.Accounts.User, foreign_key: :reviewed_by_id, type: :id)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(report, attrs) do
    report
    |> cast(attrs, [
      :user_id,
      :target_type,
      :target_id,
      :reason,
      :description,
      :status,
      :reviewed_by_id,
      :resolved_at,
      :resolution_notes
    ])
    |> validate_required([:user_id, :target_type, :target_id, :reason])
    |> validate_inclusion(:target_type, ["thread", "comment"])
    |> validate_inclusion(:reason, ["spam", "abuse", "offensive", "other"])
    |> validate_inclusion(:status, ["pending", "reviewed", "resolved", "dismissed"])
    |> validate_length(:description, max: 5000)
    |> validate_length(:resolution_notes, max: 5000)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:reviewed_by_id)
    |> unique_constraint([:user_id, :target_type, :target_id])
  end
end
