defmodule UrielmWeb.RoomChannelTest do
  use Urielm.DataCase, async: false
  import Phoenix.ChannelTest
  alias Urielm.Accounts.{Sessions, User}
  alias Urielm.Chat
  alias Urielm.Chat.{Message, RoomMembership}
  alias UrielmWeb.{RoomChannel, UserSocket}

  @endpoint UrielmWeb.Endpoint

  setup do
    user = Repo.insert!(%User{email: "channel@example.com", username: "channel"})
    other = Repo.insert!(%User{email: "other-channel@example.com", username: "otherchannel"})
    {:ok, room} = Chat.create_room(%{name: "channel-room"})
    {:ok, _} = Chat.add_member(user.id, room.id)
    {:ok, _} = Chat.add_member(other.id, room.id)
    %{user: user, other: other, room: room}
  end

  test "removed joined member is disconnected while remaining member can send", ctx do
    removed = join_room(ctx.user, ctx.room)
    remaining = join_room(ctx.other, ctx.room)
    monitor = Process.monitor(removed.channel_pid)
    Chat.remove_member(ctx.user.id, ctx.room.id)
    assert_receive {:DOWN, ^monitor, :process, _, :normal}
    push(remaining, "new_message", %{"body" => "still authorized"})
    assert_push "message_created", %{body: "still authorized"}
    assert Repo.aggregate(Message, :count) == 1
  end

  for event <- ["new_message", "typing"] do
    test "membership deleted without notification blocks inbound #{event}", ctx do
      joined = join_room(ctx.user, ctx.room)
      delete_membership(ctx)
      ref = push(joined, unquote(event), %{"body" => "forbidden"})
      assert_reply ref, :error, %{reason: "unauthorized"}
      assert Repo.aggregate(Message, :count) == 0
    end
  end

  for event <- ["message_created", "typing"] do
    test "membership deleted without notification blocks outbound #{event}", ctx do
      joined = join_room(ctx.user, ctx.room)
      monitor = Process.monitor(joined.channel_pid)
      delete_membership(ctx)
      UrielmWeb.Endpoint.broadcast("room:#{ctx.room.id}", unquote(event), %{body: "private"})
      assert_receive {:DOWN, ^monitor, :process, _, :normal}
      refute_push unquote(event), _
    end
  end

  test "silenced members can join and read but cannot post or type", ctx do
    joined = join_room(ctx.user, ctx.room)
    Repo.update!(change(ctx.user, silenced_at: DateTime.utc_now(:second)))

    for event <- ["new_message", "typing"] do
      ref = push(joined, event, %{"body" => "forbidden"})
      assert_reply ref, :error, %{reason: "silenced"}
    end

    rejoined = join_room(Repo.get!(User, ctx.user.id), ctx.room)
    UrielmWeb.Endpoint.broadcast("room:#{ctx.room.id}", "message_created", %{body: "readable"})
    assert_push "message_created", %{body: "readable"}
    assert Process.alive?(rejoined.channel_pid)
    assert Repo.aggregate(Message, :count) == 0
  end

  for attrs <- [[active: false], [suspended_at: ~U[2026-01-01 00:00:00Z]]] do
    test "current account #{inspect(attrs)} blocks incoming typing and reconnect", ctx do
      joined = join_room(ctx.user, ctx.room)
      Repo.update!(change(ctx.user, unquote(Macro.escape(attrs))))
      ref = push(joined, "typing", %{})
      assert_reply ref, :error, %{reason: "unauthorized"}

      assert {:error, %{reason: "unauthorized"}} =
               socket(UserSocket, "reconnect", %{
                 current_user: ctx.user,
                 session_token: joined.assigns.session_token
               })
               |> subscribe_and_join(RoomChannel, "room:#{ctx.room.id}")
    end
  end

  test "expired session blocks protected outbound broadcasts", ctx do
    joined = join_room(ctx.user, ctx.room)
    monitor = Process.monitor(joined.channel_pid)
    Repo.delete_all(Urielm.Accounts.UserSession)
    UrielmWeb.Endpoint.broadcast("room:#{ctx.room.id}", "message_created", %{body: "private"})
    assert_receive {:DOWN, ^monitor, :process, _, :normal}
    refute_push "message_created", _
  end

  test "authorized messages use current session identity and deliver to members", ctx do
    sender = join_room(ctx.user, ctx.room)
    receiver = join_room(ctx.other, ctx.room)
    Repo.update!(change(ctx.user, username: "freshname"))
    push(sender, "new_message", %{"body" => "hello", "user_id" => ctx.other.id})
    assert_push "message_created", %{body: "hello", user_id: user_id, username: "freshname"}
    assert user_id == ctx.user.id
    assert_push "message_created", %{body: "hello"}
    push(sender, "typing", %{"user_id" => ctx.other.id})
    assert_push "typing", %{user_id: ^user_id, username: "freshname"}
    assert Process.alive?(receiver.channel_pid)
  end

  test "validation errors are JSON safe", ctx do
    joined = join_room(ctx.user, ctx.room)
    ref = push(joined, "new_message", %{"body" => ""})
    assert_reply ref, :error, %{errors: %{body: ["can't be blank"]}} = payload
    assert {:ok, _} = Jason.encode(payload)
  end

  defp join_room(user, room) do
    token = Sessions.create(user)

    {:ok, _, joined} =
      socket(UserSocket, "user:#{user.id}", %{current_user: user, session_token: token})
      |> subscribe_and_join(RoomChannel, "room:#{room.id}")

    joined
  end

  defp delete_membership(ctx) do
    Repo.delete_all(
      from(m in RoomMembership, where: m.user_id == ^ctx.user.id and m.room_id == ^ctx.room.id)
    )
  end
end
