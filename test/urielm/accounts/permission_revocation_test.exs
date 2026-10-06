defmodule Urielm.Accounts.PermissionRevocationTest do
  use Urielm.DataCase

  import Urielm.Fixtures
  alias Urielm.Accounts
  alias Urielm.Accounts.Sessions
  alias Urielm.Repo

  test "fixes moderator demotion leaving existing sessions connected" do
    admin = admin_fixture()
    moderator = user_fixture() |> Ecto.Changeset.change(is_moderator: true) |> Repo.update!()
    token = Sessions.create(moderator)
    UrielmWeb.Endpoint.subscribe(Sessions.topic(token))

    assert {:ok, %{is_moderator: false}} = Accounts.revoke_moderator(moderator, admin)
    assert Sessions.fetch(token) == nil
    assert_receive %Phoenix.Socket.Broadcast{event: "disconnect"}
  end

  test "fixes inactive accounts retaining sessions" do
    user = user_fixture()
    token = Sessions.create(user)
    assert {:ok, %{active: false}} = Accounts.update_user(user, %{active: false})
    assert Sessions.fetch(token) == nil
  end

  test "fixes silenced accounts retaining stale live permissions" do
    user = user_fixture()
    admin = admin_fixture()
    token = Sessions.create(user)
    assert {:ok, _} = Accounts.silence_user(user, admin, reason: "spam")
    assert Sessions.fetch(token) == nil
  end

  test "revokes sessions when stale targets conceal a trust decrease or deactivation" do
    admin = admin_fixture()
    stale = user_fixture()
    current = stale |> Ecto.Changeset.change(trust_level: 4) |> Repo.update!()
    token = Sessions.create(current)
    assert {:ok, %{trust_level: 2}} = Accounts.update_trust_level(stale, 2, admin)
    assert is_nil(Sessions.fetch(token))

    inactive = current |> Ecto.Changeset.change(active: false) |> Repo.update!()
    current = inactive |> Ecto.Changeset.change(active: true) |> Repo.update!()
    token = Sessions.create(current)
    assert {:ok, %{active: false}} = Accounts.update_user(inactive, %{active: false})
    assert is_nil(Sessions.fetch(token))
  end

  test "failed account restriction preserves sessions and emits no disconnect" do
    user = user_fixture()
    token = Sessions.create(user)
    UrielmWeb.Endpoint.subscribe(Sessions.topic(token))

    assert {:error, _} = Accounts.update_user(user, %{active: false, email: "invalid"})
    assert Sessions.allowed?(token)
    refute_receive %Phoenix.Socket.Broadcast{event: "disconnect"}
  end

  test "fixes moderation APIs accepting stale or restricted actors" do
    target = user_fixture()
    admin = admin_fixture()
    moderator = user_fixture() |> Ecto.Changeset.change(is_moderator: true) |> Repo.update!()

    for actor <- [admin, moderator], restriction <- [:demoted, :inactive, :suspended] do
      attrs =
        case restriction do
          :demoted ->
            [is_admin: false, is_moderator: false, active: true, suspended_at: nil]

          :inactive ->
            [
              is_admin: actor.is_admin,
              is_moderator: actor.is_moderator,
              active: false,
              suspended_at: nil
            ]

          :suspended ->
            [
              is_admin: actor.is_admin,
              is_moderator: actor.is_moderator,
              active: true,
              suspended_at: DateTime.utc_now(:second)
            ]
        end

      Accounts.get_user(actor.id) |> Ecto.Changeset.change(attrs) |> Repo.update!()

      assert {:error, :unauthorized} = Accounts.update_trust_level(target, 2, actor)
      assert {:error, :unauthorized} = Accounts.grant_moderator(target, actor)
      assert {:error, :unauthorized} = Accounts.revoke_moderator(target, actor)
      assert {:error, :unauthorized} = Accounts.suspend_user(target, actor, reason: "spam")
      assert {:error, :unauthorized} = Accounts.unsuspend_user(target, actor)
      assert {:error, :unauthorized} = Accounts.silence_user(target, actor, reason: "spam")
      assert {:error, :unauthorized} = Accounts.unsilence_user(target, actor)
      persisted = Accounts.get_user(target.id)
      assert persisted.trust_level == target.trust_level
      refute persisted.is_moderator
      assert is_nil(persisted.suspended_at)
      assert is_nil(persisted.silenced_at)
    end
  end

  test "normal deactivation and reactivation keep old sessions revoked" do
    user = user_fixture()
    token = Sessions.create(user)
    assert {:ok, inactive} = Accounts.update_user(user, %{active: false})
    assert {:ok, _} = Accounts.update_user(inactive, %{active: true})
    assert is_nil(Sessions.fetch(token))
  end

  test "fixes reactivation reviving sessions left by direct database deactivation" do
    user = user_fixture()
    token = Sessions.create(user)
    user |> Ecto.Changeset.change(active: false) |> Repo.update!()
    assert {:ok, %{active: true}} = Accounts.update_user(user, %{active: true})
    assert is_nil(Sessions.fetch(token))
  end

  test "fixes inactive profile updates retaining residual sessions" do
    user = user_fixture()
    token = Sessions.create(user)
    user |> Ecto.Changeset.change(active: false) |> Repo.update!()
    assert {:ok, _} = Accounts.update_user(user, %{display_name: "Updated"})

    assert is_nil(
             Repo.get_by(Urielm.Accounts.UserSession, token_hash: :crypto.hash(:sha256, token))
           )
  end

  test "failed reactivation preserves account state and residual sessions" do
    user = user_fixture()
    token = Sessions.create(user)
    user |> Ecto.Changeset.change(active: false) |> Repo.update!()
    UrielmWeb.Endpoint.subscribe(Sessions.topic(token))
    assert {:error, _} = Accounts.update_user(user, %{active: true, email: "invalid"})
    refute Accounts.get_user(user.id).active
    assert Repo.get_by(Urielm.Accounts.UserSession, token_hash: :crypto.hash(:sha256, token))
    refute_receive %Phoenix.Socket.Broadcast{event: "disconnect"}
  end

  test "active profile updates preserve sessions and emit no disconnect" do
    user = user_fixture()
    token = Sessions.create(user)
    UrielmWeb.Endpoint.subscribe(Sessions.topic(token))
    assert {:ok, _} = Accounts.update_user(user, %{display_name: "Updated", active: true})
    assert Sessions.allowed?(token)
    refute_receive %Phoenix.Socket.Broadcast{event: "disconnect"}
  end

end
