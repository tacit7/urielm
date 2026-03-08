defmodule Urielm.TrustLevelTest do
  use Urielm.DataCase, async: true

  import Urielm.Fixtures

  alias Urielm.TrustLevel

  setup do
    TrustLevel.get_or_create_defaults()
    :ok
  end

  describe "get_config/1" do
    test "returns config for each trust level" do
      for level <- 0..4 do
        config = TrustLevel.get_config(level)
        assert config.level == level
        assert config.name != nil
      end
    end
  end

  describe "list_configs/0" do
    test "returns all 5 trust level configs ordered by level" do
      configs = TrustLevel.list_configs()
      assert length(configs) == 5
      assert Enum.map(configs, & &1.level) == [0, 1, 2, 3, 4]
    end
  end

  describe "permissions by trust level" do
    test "level 0 (New) has no elevated permissions" do
      user = set_trust_level(user_fixture(), 0)
      refute TrustLevel.can_pin_topics?(user)
      refute TrustLevel.can_feature_topics?(user)
      refute TrustLevel.can_close_topics?(user)
      refute TrustLevel.can_moderate?(user)
    end

    test "level 1 (Basic) has no elevated permissions" do
      user = set_trust_level(user_fixture(), 1)
      refute TrustLevel.can_pin_topics?(user)
      refute TrustLevel.can_moderate?(user)
    end

    test "level 3 (Regular) can pin topics but not moderate" do
      user = set_trust_level(user_fixture(), 3)
      assert TrustLevel.can_pin_topics?(user)
      refute TrustLevel.can_moderate?(user)
    end

    test "level 4 (Leader) has full permissions" do
      user = set_trust_level(user_fixture(), 4)
      assert TrustLevel.can_pin_topics?(user)
      assert TrustLevel.can_feature_topics?(user)
      assert TrustLevel.can_close_topics?(user)
      assert TrustLevel.can_moderate?(user)
    end
  end

  describe "rate limits by trust level" do
    test "level 0 has the lowest posting rate limit" do
      user = set_trust_level(user_fixture(), 0)
      assert TrustLevel.get_max_posts_per_minute(user) == 1
    end

    test "level 4 has no posting rate limit" do
      user = set_trust_level(user_fixture(), 4)
      assert TrustLevel.get_max_posts_per_minute(user) == -1
    end

    test "higher trust levels have higher daily topic limits" do
      config_0 = TrustLevel.get_config(0)
      config_2 = TrustLevel.get_config(2)
      assert config_2.max_new_topics_per_day > config_0.max_new_topics_per_day
    end

    test "level 4 has no daily topic limit" do
      user = set_trust_level(user_fixture(), 4)
      assert TrustLevel.get_max_new_topics_per_day(user) == -1
    end
  end

  describe "edit time limits by trust level" do
    test "level 0 has a 5-minute edit window" do
      user = set_trust_level(user_fixture(), 0)
      assert TrustLevel.get_post_edit_time_limit(user) == 5
    end

    test "level 4 has unlimited edit time" do
      user = set_trust_level(user_fixture(), 4)
      assert TrustLevel.get_post_edit_time_limit(user) == -1
    end
  end

  describe "update_config/2" do
    test "updates a trust level config field" do
      {:ok, updated} = TrustLevel.update_config(1, %{max_new_topics_per_day: 15})
      assert updated.max_new_topics_per_day == 15
    end

    test "persists the update" do
      TrustLevel.update_config(2, %{max_posts_per_minute: 8})
      config = TrustLevel.get_config(2)
      assert config.max_posts_per_minute == 8
    end
  end

  defp set_trust_level(user, level) do
    user
    |> Ecto.Changeset.change(%{trust_level: level})
    |> Urielm.Repo.update!()
  end
end
