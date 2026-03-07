defmodule Urielm.Accounts.UserManagementTest do
  use Urielm.DataCase, async: true

  import Urielm.Fixtures

  alias Urielm.Accounts

  setup do
    admin = admin_fixture()
    mod = make_moderator(user_fixture())
    regular = user_fixture()
    target = user_fixture()

    %{admin: admin, mod: mod, regular: regular, target: target}
  end

  defp make_moderator(user) do
    user
    |> Ecto.Changeset.change(%{is_moderator: true})
    |> Urielm.Repo.update!()
  end

  defp default_params do
    %{page: 1, page_size: 10, order_by: [:inserted_at], order_directions: [:desc]}
  end

  describe "paginate_users/2" do
    test "returns all users with default params" do
      user1 = user_fixture()
      user2 = user_fixture()

      {:ok, {users, _meta}} = Accounts.paginate_users(default_params())

      ids = Enum.map(users, & &1.id)
      assert user1.id in ids
      assert user2.id in ids
    end

    test "returns {:ok, {users, meta}} tuple" do
      result = Accounts.paginate_users(default_params())
      assert {:ok, {users, meta}} = result
      assert is_list(users)
      assert is_struct(meta, Flop.Meta)
    end

    test "search by username (partial, case-insensitive)" do
      suffix = unique_hex()
      target = user_fixture(%{username: "find#{suffix}"})

      {:ok, {users, _meta}} = Accounts.paginate_users(default_params(), search: "FIND#{suffix}")

      ids = Enum.map(users, & &1.id)
      assert target.id in ids
    end

    test "search by email (partial match)" do
      suffix = unique_hex()
      target = user_fixture(%{email: "find#{suffix}@example.com", username: "srch#{suffix}"})

      {:ok, {users, _meta}} = Accounts.paginate_users(default_params(), search: "find#{suffix}")

      ids = Enum.map(users, & &1.id)
      assert target.id in ids
    end

    test "filter status 'active' excludes suspended and silenced users", %{admin: admin} do
      active = user_fixture()
      suspended_user = user_fixture()
      silenced_user = user_fixture()

      {:ok, _} = Accounts.suspend_user(suspended_user, admin, reason: "test")
      {:ok, _} = Accounts.silence_user(silenced_user, admin, reason: "test")

      {:ok, {users, _meta}} = Accounts.paginate_users(default_params(), status: "active")

      ids = Enum.map(users, & &1.id)
      assert active.id in ids
      refute suspended_user.id in ids
      refute silenced_user.id in ids
    end

    test "filter status 'suspended' returns only suspended users", %{admin: admin} do
      active = user_fixture()
      to_suspend = user_fixture()

      {:ok, suspended_user} = Accounts.suspend_user(to_suspend, admin, reason: "test")

      {:ok, {users, _meta}} = Accounts.paginate_users(default_params(), status: "suspended")

      ids = Enum.map(users, & &1.id)
      assert suspended_user.id in ids
      refute active.id in ids
    end

    test "filter status 'silenced' returns only silenced users", %{admin: admin} do
      active = user_fixture()
      to_silence = user_fixture()

      {:ok, silenced_user} = Accounts.silence_user(to_silence, admin, reason: "test")

      {:ok, {users, _meta}} = Accounts.paginate_users(default_params(), status: "silenced")

      ids = Enum.map(users, & &1.id)
      assert silenced_user.id in ids
      refute active.id in ids
    end
  end

  describe "update_trust_level/3" do
    test "admin can set trust level 0", %{admin: admin, target: target} do
      {:ok, updated} = Accounts.update_trust_level(target, 0, admin)
      assert updated.trust_level == 0
    end

    test "admin can set trust level 4", %{admin: admin, target: target} do
      {:ok, updated} = Accounts.update_trust_level(target, 4, admin)
      assert updated.trust_level == 4
    end

    test "moderator cannot update trust level", %{mod: mod, target: target} do
      assert {:error, :unauthorized} = Accounts.update_trust_level(target, 2, mod)
    end

    test "regular user cannot update trust level", %{regular: regular, target: target} do
      assert {:error, :unauthorized} = Accounts.update_trust_level(target, 2, regular)
    end
  end

  defp unique_hex do
    :crypto.strong_rand_bytes(6) |> Base.encode16(case: :lower)
  end
end
