defmodule Urielm.Billing do
  @moduledoc """
  The Billing context for managing subscriptions.
  """

  import Ecto.Query, warn: false
  alias Urielm.Repo
  alias Urielm.Billing.Subscription
  alias Urielm.Accounts.User

  @doc """
  Checks if a user has an active subscription.

  Returns true if:
  - User has a subscription with status "active"
  - AND either no period_end or period_end is in the future

  ## Examples

      iex> active_subscription?(%User{id: 123})
      true

      iex> active_subscription?(nil)
      false

  """
  def active_subscription?(%User{id: user_id}) do
    now = DateTime.utc_now()

    from(s in Subscription,
      where: s.user_id == ^user_id,
      where: s.status == "active",
      where: is_nil(s.current_period_end) or s.current_period_end > ^now
    )
    |> Repo.exists?()
  end

  def active_subscription?(nil), do: false
end
