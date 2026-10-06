defmodule Urielm.Accounts.Sessions do
  @moduledoc "Server-tracked, expiring authentication sessions. Only token hashes are persisted."
  import Ecto.Query
  alias Urielm.Accounts.{User, UserSession}
  alias Urielm.Repo

  @lifetime 30 * 24 * 60 * 60
  def lifetime, do: @lifetime

  def create(%User{} = user, context \\ "session") do
    token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
    seconds = if context == "signup", do: 600, else: @lifetime

    Repo.insert!(%UserSession{
      user_id: user.id,
      token_hash: hash(token),
      credential_hash: credential_hash(user),
      context: context,
      expires_at: DateTime.add(DateTime.utc_now(:second), seconds, :second)
    })

    token
  end

  def fetch(token, context \\ "session")

  def fetch(token, context) when is_binary(token) and byte_size(token) == 43 do
    now = DateTime.utc_now(:second)

    case Repo.one(
           from(s in UserSession,
             join: u in assoc(s, :user),
             where:
               s.token_hash == ^hash(token) and s.context == ^context and s.expires_at > ^now,
             select: {u, s}
           )
         ) do
      {user, session} ->
        if session.credential_hash == credential_hash(user), do: {user, session}, else: nil

      nil ->
        nil
    end
  end

  def fetch(_, _), do: nil

  def user(token) do
    case fetch(token) do
      {user, _} -> user
      nil -> nil
    end
  end

  def allowed?(token) do
    case user(token) do
      nil -> false
      user -> user.active && !User.suspended?(user)
    end
  end

  def purge_expired do
    now = DateTime.utc_now(:second)
    {count, _} = Repo.delete_all(from(s in UserSession, where: s.expires_at <= ^now))
    count
  end

  def revoke(token) when is_binary(token) do
    Repo.delete_all(from(s in UserSession, where: s.token_hash == ^hash(token)))
    disconnect_hash(hash(token))
    :ok
  end

  def revoke(_), do: :ok

  # Called inside the password-update transaction; broadcast only after commit.
  def delete_for_user(user_id) do
    {_count, sessions} =
      Repo.delete_all(from(s in UserSession, where: s.user_id == ^user_id, select: s.token_hash))

    sessions
  end

  def disconnect_hash(token_hash) do
    UrielmWeb.Endpoint.broadcast(topic_hash(token_hash), "disconnect", %{})
  end

  def topic(token), do: topic_hash(hash(token))
  defp topic_hash(token_hash), do: "session:" <> Base.url_encode64(token_hash, padding: false)
  defp hash(value), do: :crypto.hash(:sha256, value)
  defp credential_hash(user), do: hash(user.password_hash || "")

  # Consuming the signup grant atomically prevents replay from creating a fresh session.
  def consume_signup(token) do
    case fetch(token, "signup") do
      {user, session} ->
        case Repo.delete_all(from(s in UserSession, where: s.id == ^session.id)) do
          {1, _} -> user
          _ -> nil
        end

      nil ->
        nil
    end
  end
end
