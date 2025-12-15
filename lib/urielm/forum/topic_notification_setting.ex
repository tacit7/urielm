defmodule Urielm.Forum.TopicNotificationSetting do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "forum_topic_notification_settings" do
    field(:notification_level, :string, default: "watching")
    # watching: receive all notifications
    # tracking: receive summary notifications
    # muted: no notifications

    belongs_to(:user, Urielm.Accounts.User, type: :id)
    belongs_to(:thread, Urielm.Forum.Thread)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(setting, attrs) do
    setting
    |> cast(attrs, [:user_id, :thread_id, :notification_level])
    |> validate_required([:user_id, :thread_id, :notification_level])
    |> validate_inclusion(:notification_level, ["watching", "tracking", "muted"])
    |> unique_constraint([:user_id, :thread_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:thread_id)
  end
end
