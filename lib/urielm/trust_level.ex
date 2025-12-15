defmodule Urielm.TrustLevel do
  @moduledoc """
  Trust level system: configurable user tiers with permissions and rate limits.
  Users auto-promote based on activity thresholds.
  """

  import Ecto.Query, warn: false
  alias Urielm.Repo
  alias Urielm.TrustLevelConfig

  # Get or create default trust level configurations
  def get_or_create_defaults do
    # Check if configs exist
    case Repo.all(TrustLevelConfig) do
      [] -> create_default_configs()
      configs -> configs
    end
  end

  defp create_default_configs do
    defaults = [
      %{
        level: 0,
        name: "New",
        color: "gray",
        min_topics: 0,
        min_posts: 0,
        min_days_joined: 0,
        max_posts_per_minute: 1,
        max_new_topics_per_day: 3,
        post_edit_time_limit: 5,
        can_pin_topics: false,
        can_feature_topics: false,
        can_close_topics: false,
        can_moderate: false
      },
      %{
        level: 1,
        name: "Basic",
        color: "blue",
        min_topics: 10,
        min_posts: 50,
        min_days_joined: 3,
        max_posts_per_minute: 5,
        max_new_topics_per_day: 10,
        post_edit_time_limit: 60,
        can_pin_topics: false,
        can_feature_topics: false,
        can_close_topics: false,
        can_moderate: false
      },
      %{
        level: 2,
        name: "Member",
        color: "green",
        min_topics: 50,
        min_posts: 500,
        min_days_joined: 30,
        max_posts_per_minute: 10,
        max_new_topics_per_day: 20,
        post_edit_time_limit: 1440,
        can_pin_topics: false,
        can_feature_topics: false,
        can_close_topics: false,
        can_moderate: false
      },
      %{
        level: 3,
        name: "Regular",
        color: "purple",
        min_topics: 100,
        min_posts: 1000,
        min_days_joined: 60,
        max_posts_per_minute: 20,
        max_new_topics_per_day: 50,
        post_edit_time_limit: -1,
        can_pin_topics: true,
        can_feature_topics: false,
        can_close_topics: false,
        can_moderate: false
      },
      %{
        level: 4,
        name: "Leader",
        color: "red",
        min_topics: 200,
        min_posts: 2000,
        min_days_joined: 120,
        max_posts_per_minute: -1,
        max_new_topics_per_day: -1,
        post_edit_time_limit: -1,
        can_pin_topics: true,
        can_feature_topics: true,
        can_close_topics: true,
        can_moderate: true
      }
    ]

    Enum.each(defaults, fn attrs ->
      %TrustLevelConfig{}
      |> TrustLevelConfig.changeset(attrs)
      |> Repo.insert!()
    end)

    Repo.all(TrustLevelConfig)
  end

  def get_config(level) do
    Repo.get_by(TrustLevelConfig, level: level) ||
      get_or_create_defaults() |> Enum.find(&(&1.level == level))
  end

  def list_configs do
    Repo.all(from(tlc in TrustLevelConfig, order_by: [asc: tlc.level]))
  end

  def update_config(level, attrs) do
    get_config(level)
    |> TrustLevelConfig.changeset(attrs)
    |> Repo.update()
  end

  # Check if user can perform action based on trust level
  def can_post_topic?(user) do
    config = get_config(user.trust_level)
    # All levels can post except in special cases
    config && !config.can_moderate
  end

  def can_pin_topics?(user) do
    config = get_config(user.trust_level)
    config && config.can_pin_topics
  end

  def can_feature_topics?(user) do
    config = get_config(user.trust_level)
    config && config.can_feature_topics
  end

  def can_close_topics?(user) do
    config = get_config(user.trust_level)
    config && config.can_close_topics
  end

  def can_moderate?(user) do
    config = get_config(user.trust_level)
    config && config.can_moderate
  end

  def get_post_edit_time_limit(user) do
    config = get_config(user.trust_level)
    config && config.post_edit_time_limit
  end

  def get_max_posts_per_minute(user) do
    config = get_config(user.trust_level)
    config && config.max_posts_per_minute
  end

  def get_max_new_topics_per_day(user) do
    config = get_config(user.trust_level)
    config && config.max_new_topics_per_day
  end
end
