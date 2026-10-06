defmodule Urielm.Accounts.PostingAuthorization do
  @moduledoc "Authorizes posting against the account's current persisted status."

  alias Urielm.Accounts.User
  alias Urielm.Repo

  def authorize(user_id) when is_integer(user_id) do
    case Repo.get(User, user_id) do
      nil -> {:error, :unauthenticated}
      user -> authorize_account(user)
    end
  end

  def authorize(_), do: {:error, :unauthenticated}

  defp authorize_account(user) do
    cond do
      !user.active -> {:error, :inactive}
      User.suspended?(user) -> {:error, :suspended}
      User.silenced?(user) -> {:error, :silenced}
      !user.email_verified -> {:error, :email_not_verified}
      true -> :ok
    end
  end

  def message(:email_not_verified), do: "Verify your email before commenting."
  def message(:silenced), do: "Your account is silenced and cannot comment."
  def message(:suspended), do: "Your account is suspended and cannot comment."
  def message(:inactive), do: "Your account is inactive and cannot comment."
  def message(:unauthenticated), do: "Sign in to comment."
end
