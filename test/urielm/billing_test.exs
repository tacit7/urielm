defmodule Urielm.BillingTest do
  use Urielm.DataCase
  import Urielm.Fixtures

  alias Urielm.Billing
  alias Urielm.Billing.Subscription

  describe "active_subscription?/1" do
    setup do
      user = user_fixture()
      %{user: user}
    end

    test "returns false for nil user" do
      assert Billing.active_subscription?(nil) == false
    end

    test "returns false when user has no subscription", %{user: user} do
      assert Billing.active_subscription?(user) == false
    end

    test "returns true when user has active subscription with no end date", %{user: user} do
      subscription_fixture(user, %{status: "active", current_period_end: nil})
      assert Billing.active_subscription?(user) == true
    end

    test "returns true when user has active subscription with future end date", %{user: user} do
      future_date = DateTime.add(DateTime.utc_now(), 30, :day) |> DateTime.truncate(:second)
      subscription_fixture(user, %{status: "active", current_period_end: future_date})
      assert Billing.active_subscription?(user) == true
    end

    test "returns false when subscription is expired", %{user: user} do
      past_date = DateTime.add(DateTime.utc_now(), -1, :day) |> DateTime.truncate(:second)
      subscription_fixture(user, %{status: "active", current_period_end: past_date})
      assert Billing.active_subscription?(user) == false
    end

    test "returns false when subscription status is canceled", %{user: user} do
      subscription_fixture(user, %{status: "canceled", current_period_end: nil})
      assert Billing.active_subscription?(user) == false
    end

    test "returns false when subscription status is past_due", %{user: user} do
      subscription_fixture(user, %{status: "past_due", current_period_end: nil})
      assert Billing.active_subscription?(user) == false
    end
  end
end
