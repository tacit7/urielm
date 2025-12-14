defmodule Urielm.Forum.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "forum_notifications" do
    field(:subject_type, :string)
    field(:subject_id, :binary_id)
    field(:message, :string)
    field(:read_at, :utc_datetime_usec)

    belongs_to(:user, Urielm.Accounts.User, type: :id)
    belongs_to(:actor, Urielm.Accounts.User, foreign_key: :actor_id, type: :id)
    belongs_to(:thread, Urielm.Forum.Thread)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:user_id, :actor_id, :subject_type, :subject_id, :thread_id, :message, :read_at])
    |> validate_required([:user_id, :subject_type, :subject_id])
    |> validate_inclusion(:subject_type, ["comment", "reply", "thread_update"])
    |> validate_length(:message, max: 500)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:actor_id)
    |> foreign_key_constraint(:thread_id)
  end
end
