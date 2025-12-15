defmodule Urielm.TrustLevelConfig do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "trust_level_configs" do
    field(:level, :integer)
    field(:name, :string)
    field(:color, :string)
    field(:min_topics, :integer, default: 0)
    field(:min_posts, :integer, default: 0)
    field(:min_days_joined, :integer, default: 0)
    field(:min_likes_given, :integer, default: 0)
    field(:min_likes_received, :integer, default: 0)
    field(:max_posts_per_minute, :integer)
    field(:max_new_topics_per_day, :integer)
    field(:permissions, :map, default: %{})
    field(:post_edit_time_limit, :integer, default: 5)
    field(:can_pin_topics, :boolean, default: false)
    field(:can_feature_topics, :boolean, default: false)
    field(:can_close_topics, :boolean, default: false)
    field(:can_moderate, :boolean, default: false)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(config, attrs) do
    config
    |> cast(attrs, [
      :level,
      :name,
      :color,
      :min_topics,
      :min_posts,
      :min_days_joined,
      :min_likes_given,
      :min_likes_received,
      :max_posts_per_minute,
      :max_new_topics_per_day,
      :permissions,
      :post_edit_time_limit,
      :can_pin_topics,
      :can_feature_topics,
      :can_close_topics,
      :can_moderate
    ])
    |> validate_required([
      :level,
      :name,
      :color,
      :max_posts_per_minute,
      :max_new_topics_per_day
    ])
    |> validate_inclusion(:level, 0..4)
    |> unique_constraint(:level)
  end
end
