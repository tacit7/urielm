defmodule Urielm.Accounts.ModerationTest do
  use Urielm.DataCase, async: true

  import Urielm.Fixtures

  alias Urielm.Accounts
  alias Urielm.Accounts.User

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

  describe "grant_moderator/2" do
    test "admin can grant moderator role", %{admin: admin, target: target} do
      {:ok, updated} = Accounts.grant_moderator(target, admin)
      assert updated.is_moderator == true
    end

    test "moderator cannot grant moderator role", %{mod: mod, target: target} do
      assert {:error, :unauthorized} = Accounts.grant_moderator(target, mod)
    end

    test "regular user cannot grant moderator role", %{regular: regular, target: target} do
      assert {:error, :unauthorized} = Accounts.grant_moderator(target, regular)
    end
  end

  describe "revoke_moderator/2" do
    test "admin can revoke moderator role", %{admin: admin, mod: mod} do
      {:ok, updated} = Accounts.revoke_moderator(mod, admin)
      assert updated.is_moderator == false
    end

    test "moderator cannot revoke another moderator", %{mod: mod} do
      other_mod = make_moderator(user_fixture())
      assert {:error, :unauthorized} = Accounts.revoke_moderator(other_mod, mod)
    end

    test "regular user cannot revoke moderator role", %{regular: regular, mod: mod} do
      assert {:error, :unauthorized} = Accounts.revoke_moderator(mod, regular)
    end
  end

  describe "suspend_user/3" do
    test "admin can suspend a user", %{admin: admin, target: target} do
      {:ok, suspended} = Accounts.suspend_user(target, admin, reason: "Spam")
      assert suspended.suspended_at != nil
      assert suspended.suspended_reason == "Spam"
      assert suspended.suspended_until == nil
    end

    test "moderator can suspend a user", %{mod: mod, target: target} do
      {:ok, suspended} = Accounts.suspend_user(target, mod, reason: "Harassment")
      assert suspended.suspended_at != nil
    end

    test "can suspend with an expiry date", %{admin: admin, target: target} do
      until = DateTime.utc_now() |> DateTime.add(7 * 86400, :second) |> DateTime.truncate(:second)
      {:ok, suspended} = Accounts.suspend_user(target, admin, reason: "Temp ban", until: until)

      assert suspended.suspended_until != nil
    end

    test "regular user cannot suspend", %{regular: regular, target: target} do
      assert {:error, :unauthorized} = Accounts.suspend_user(target, regular, reason: "Test")
    end

    test "User.suspended?/1 returns true for suspended user", %{admin: admin, target: target} do
      {:ok, suspended} = Accounts.suspend_user(target, admin, reason: "Test")
      assert User.suspended?(suspended)
    end

    test "User.suspended?/1 returns false for active user", %{target: target} do
      refute User.suspended?(target)
    end
  end

  describe "unsuspend_user/2" do
    test "admin can unsuspend a user", %{admin: admin, target: target} do
      {:ok, suspended} = Accounts.suspend_user(target, admin, reason: "Test")
      {:ok, unsuspended} = Accounts.unsuspend_user(suspended, admin)

      assert unsuspended.suspended_at == nil
      assert unsuspended.suspended_reason == nil
      refute User.suspended?(unsuspended)
    end

    test "moderator can unsuspend a user", %{admin: admin, mod: mod, target: target} do
      {:ok, suspended} = Accounts.suspend_user(target, admin, reason: "Test")
      {:ok, unsuspended} = Accounts.unsuspend_user(suspended, mod)
      assert unsuspended.suspended_at == nil
    end

    test "regular user cannot unsuspend", %{admin: admin, regular: regular, target: target} do
      {:ok, suspended} = Accounts.suspend_user(target, admin, reason: "Test")
      assert {:error, :unauthorized} = Accounts.unsuspend_user(suspended, regular)
    end
  end

  describe "silence_user/3" do
    test "admin can silence a user", %{admin: admin, target: target} do
      {:ok, silenced} = Accounts.silence_user(target, admin, reason: "Trolling")
      assert silenced.silenced_at != nil
      assert silenced.silenced_reason == "Trolling"
      assert silenced.silenced_until == nil
    end

    test "moderator can silence a user", %{mod: mod, target: target} do
      {:ok, silenced} = Accounts.silence_user(target, mod, reason: "Spam")
      assert silenced.silenced_at != nil
    end

    test "can silence with an expiry date", %{admin: admin, target: target} do
      until = DateTime.utc_now() |> DateTime.add(3 * 86400, :second) |> DateTime.truncate(:second)
      {:ok, silenced} = Accounts.silence_user(target, admin, reason: "Temp", until: until)
      assert silenced.silenced_until != nil
    end

    test "regular user cannot silence", %{regular: regular, target: target} do
      assert {:error, :unauthorized} = Accounts.silence_user(target, regular, reason: "Test")
    end

    test "User.silenced?/1 returns true for silenced user", %{admin: admin, target: target} do
      {:ok, silenced} = Accounts.silence_user(target, admin, reason: "Test")
      assert User.silenced?(silenced)
    end

    test "User.silenced?/1 returns false for active user", %{target: target} do
      refute User.silenced?(target)
    end
  end

  describe "unsilence_user/2" do
    test "admin can unsilence a user", %{admin: admin, target: target} do
      {:ok, silenced} = Accounts.silence_user(target, admin, reason: "Test")
      {:ok, unsilenced} = Accounts.unsilence_user(silenced, admin)

      assert unsilenced.silenced_at == nil
      assert unsilenced.silenced_reason == nil
      refute User.silenced?(unsilenced)
    end

    test "moderator can unsilence a user", %{admin: admin, mod: mod, target: target} do
      {:ok, silenced} = Accounts.silence_user(target, admin, reason: "Test")
      {:ok, unsilenced} = Accounts.unsilence_user(silenced, mod)
      assert unsilenced.silenced_at == nil
    end

    test "regular user cannot unsilence", %{admin: admin, regular: regular, target: target} do
      {:ok, silenced} = Accounts.silence_user(target, admin, reason: "Test")
      assert {:error, :unauthorized} = Accounts.unsilence_user(silenced, regular)
    end
  end
end
