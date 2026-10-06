defmodule Urielm.Accounts.SessionsTest do
  use Urielm.DataCase
  import Urielm.Fixtures
  alias Urielm.Accounts.{Sessions, UserSession}
  alias Urielm.Accounts

  test "the scheduled cleaner purges expired sessions and signup grants while preserving live sessions" do
    user = user_fixture()
    active = Sessions.create(user)
    expired = Sessions.create(user)
    grant = Sessions.create(user, "signup")
    hashes = Enum.map([expired, grant], &:crypto.hash(:sha256, &1))

    Repo.update_all(from(s in UserSession, where: s.token_hash in ^hashes),
      set: [expires_at: DateTime.add(DateTime.utc_now(:second), -1)]
    )

    cleaner = Process.whereis(Urielm.Accounts.SessionCleaner)
    assert cleaner
    send(cleaner, :purge_expired)
    :sys.get_state(cleaner)
    assert Repo.aggregate(from(s in UserSession, where: s.token_hash in ^hashes), :count) == 0
    assert Sessions.user(active).id == user.id
  end

  test "tokens are unique, stored as hashes, and invalid after expiry" do
    user = user_fixture()
    token = Sessions.create(user)
    other = Sessions.create(user)
    refute token == other
    {authenticated, record} = Sessions.fetch(token)
    assert authenticated.id == user.id
    refute record.token_hash == token
    assert record.token_hash == :crypto.hash(:sha256, token)

    Repo.update_all(from(s in UserSession, where: s.id == ^record.id),
      set: [expires_at: DateTime.add(DateTime.utc_now(:second), -1)]
    )

    assert Sessions.user(token) == nil
    assert Sessions.user(other).id == user.id
    assert Sessions.user(nil) == nil
    assert Sessions.user("malformed") == nil
  end

  test "password changes revoke every device and signup grant and broadcast disconnects" do
    user = user_fixture()
    tokens = [Sessions.create(user), Sessions.create(user)]
    grant = Sessions.create(user, "signup")
    Enum.each(tokens, &Phoenix.PubSub.subscribe(Urielm.PubSub, Sessions.topic(&1)))
    assert {:ok, _} = Accounts.update_user_password(user, %{password: "newpassword123"})

    Enum.each(tokens, fn token ->
      assert Sessions.user(token) == nil
      topic = Sessions.topic(token)
      assert_receive %Phoenix.Socket.Broadcast{topic: ^topic, event: "disconnect"}
    end)

    assert Sessions.consume_signup(grant) == nil
    # A concurrent login using credentials fetched before the password change cannot
    # create a valid session even if its insertion happens after revocation.
    assert user |> Sessions.create() |> Sessions.user() == nil
  end

  test "invalid password change preserves sessions and signup grants are single use" do
    user = user_fixture()
    token = Sessions.create(user)
    assert {:error, _} = Accounts.update_user_password(user, %{password: "short"})
    assert Sessions.user(token).id == user.id
    grant = Sessions.create(user, "signup")
    assert Sessions.user(grant) == nil
    assert Sessions.consume_signup(grant).id == user.id
    assert Sessions.consume_signup(grant) == nil
  end
end
