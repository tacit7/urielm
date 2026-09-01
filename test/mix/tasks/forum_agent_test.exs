defmodule Mix.Tasks.Forum.AgentTest do
  use Urielm.DataCase

  import Urielm.Fixtures

  alias Mix.Tasks.Forum.Agent
  alias Urielm.Forum

  setup do
    previous_shell = Mix.shell()
    Mix.shell(Mix.Shell.Process)
    Mix.Task.reenable("forum.agent")

    on_exit(fn ->
      Mix.shell(previous_shell)
      Mix.Task.reenable("forum.agent")
    end)
  end

  test "show prints thread comments so agents can inspect replies" do
    author = user_fixture(%{username: "agent_author"})
    replier = user_fixture(%{username: "agent_replier"})
    thread = thread_fixture(%{author_id: author.id, title: "Agent visible thread"})
    comment = comment_fixture(thread, replier, %{body: "First visible reply"})

    shown = Agent.run(["show", thread.id])

    assert shown.id == thread.id
    assert_received {:mix_shell, :info, [message]}
    assert message =~ "Agent visible thread"
    assert message =~ comment.id
    assert message =~ "agent_replier"
    assert message =~ "First visible reply"
  end

  test "comment posts a top-level reply as the agent user" do
    agent = user_fixture(%{username: "forum_agent"})
    thread = thread_fixture()

    comment =
      Agent.run([
        "comment",
        "--agent",
        "forum_agent",
        "--thread",
        thread.id,
        "--body",
        "This reply came from the agent CLI."
      ])

    assert comment.author_id == agent.id
    assert comment.body == "This reply came from the agent CLI."
    assert comment.parent_id == nil
    assert_received {:mix_shell, :info, [message]}
    assert message =~ "Posted comment:"
    assert message =~ comment.id
  end

  test "reply posts under a parent comment" do
    agent = user_fixture(%{username: "reply_agent"})
    thread = thread_fixture()
    parent = comment_fixture(thread)

    reply =
      Agent.run([
        "reply",
        "--agent-id",
        Integer.to_string(agent.id),
        "--thread",
        thread.id,
        "--parent",
        parent.id,
        "--body",
        "Nested response from the agent."
      ])

    assert reply.author_id == agent.id
    assert reply.parent_id == parent.id
  end

  test "reply can set created-at timestamp" do
    agent = user_fixture(%{username: "dated_reply_agent"})
    thread = thread_fixture()

    reply =
      Agent.run([
        "comment",
        "--agent",
        agent.username,
        "--thread",
        thread.id,
        "--body",
        "Backfilled response from the agent.",
        "--created-at",
        "2026-08-30T09:15:00Z"
      ])

    assert DateTime.compare(reply.inserted_at, ~U[2026-08-30 09:15:00Z]) == :eq
  end

  test "thread creates a forum thread as the agent user" do
    agent = user_fixture(%{username: "thread_agent"})
    board = board_fixture(%{slug: "agent-board"})

    thread =
      Agent.run([
        "thread",
        "--agent",
        "thread_agent",
        "--board",
        "agent-board",
        "--title",
        "Agent-created topic",
        "--body",
        "This is a long enough thread body created through the CLI."
      ])

    assert thread.author_id == agent.id
    assert thread.board_id == board.id
    assert thread.slug == "agent-created-topic"
    assert_received {:mix_shell, :info, [message]}
    assert message =~ "Created thread:"
    assert message =~ "/forum/t/#{thread.id}"
  end

  test "thread can set created-at timestamp" do
    agent = user_fixture(%{username: "dated_thread_agent"})
    board = board_fixture(%{slug: "dated-agent-board"})

    thread =
      Agent.run([
        "thread",
        "--agent",
        agent.username,
        "--board",
        board.slug,
        "--title",
        "Backfilled agent topic",
        "--body",
        "This backfilled body is long enough for thread validation.",
        "--created-at",
        "2026-08-31T12:34:56Z"
      ])

    assert DateTime.compare(thread.inserted_at, ~U[2026-08-31 12:34:56Z]) == :eq
  end

  test "json output is parseable for agents" do
    thread = thread_fixture()

    Agent.run(["show", thread.id, "--json"])

    assert_received {:mix_shell, :info, [message]}
    assert {:ok, %{"thread" => %{"id" => id}, "comments" => []}} = Jason.decode(message)
    assert id == thread.id
  end

  test "inbox shows notifications for an agent user" do
    agent = user_fixture(%{username: "inbox_agent"})
    actor = user_fixture(%{username: "inbox_actor"})
    thread = thread_fixture()

    {:ok, notification} =
      Forum.create_notification(agent.id, "comment", thread.id, %{
        actor_id: actor.id,
        thread_id: thread.id,
        message: "inbox_actor replied to a thread"
      })

    notifications = Agent.run(["inbox", "--agent", agent.username])

    assert Enum.map(notifications, & &1.id) == [notification.id]
    assert_received {:mix_shell, :info, [message]}
    assert message =~ "Inbox:"
    assert message =~ "Unread: 1"
    assert message =~ notification.id
    assert message =~ "inbox_actor"
    assert message =~ thread.title
    assert message =~ "/forum/t/#{thread.id}"
  end

  test "inbox json output includes thread and actor metadata" do
    agent = user_fixture(%{username: "json_inbox_agent"})
    actor = user_fixture(%{username: "json_inbox_actor"})
    thread = thread_fixture()

    {:ok, notification} =
      Forum.create_notification(agent.id, "reply", thread.id, %{
        actor_id: actor.id,
        thread_id: thread.id,
        message: "json_inbox_actor replied to you"
      })

    Agent.run(["inbox", "--agent", agent.username, "--json"])

    assert_received {:mix_shell, :info, [message]}

    assert {:ok,
            %{
              "agent" => %{"username" => "json_inbox_agent"},
              "unread_count" => 1,
              "notifications" => [
                %{
                  "id" => id,
                  "thread_id" => thread_id,
                  "actor_username" => "json_inbox_actor"
                }
              ]
            }} = Jason.decode(message)

    assert id == notification.id
    assert thread_id == thread.id
  end

  test "inbox can filter unread and mark notifications read" do
    agent = user_fixture(%{username: "mark_read_agent"})
    thread = thread_fixture()

    {:ok, read_notification} = Forum.create_notification(agent.id, "comment", thread.id)
    {:ok, unread_notification} = Forum.create_notification(agent.id, "reply", thread.id)
    {:ok, _updated} = Forum.mark_notification_as_read(agent.id, read_notification.id)

    notifications = Agent.run(["inbox", "--agent", agent.username, "--unread", "--mark-read"])

    assert Enum.map(notifications, & &1.id) == [unread_notification.id]
    assert Forum.count_unread_notifications(agent.id) == 0
  end

  test "missing agent raises a clear error" do
    thread = thread_fixture()

    assert_raise Mix.Error, "Agent user not found: missing_agent", fn ->
      Agent.run([
        "comment",
        "--agent",
        "missing_agent",
        "--thread",
        thread.id,
        "--body",
        "Body"
      ])
    end

    assert_received {:mix_shell, :error, ["Agent user not found: missing_agent"]}
  end

  test "body-file is accepted for long posts" do
    agent = user_fixture(%{username: "file_agent"})
    thread = thread_fixture()

    path =
      Path.join(System.tmp_dir!(), "forum-agent-body-#{System.unique_integer([:positive])}.md")

    File.write!(path, "Body loaded from disk.")

    try do
      comment =
        Agent.run([
          "comment",
          "--agent",
          agent.username,
          "--thread",
          thread.id,
          "--body-file",
          path
        ])

      assert comment.body == "Body loaded from disk."
    after
      File.rm(path)
    end
  end

  test "invalid parent comment is reported clearly" do
    agent = user_fixture(%{username: "invalid_parent_agent"})
    thread = thread_fixture()
    other_thread = thread_fixture()
    other_parent = comment_fixture(other_thread)

    assert_raise Mix.Error, "Could not post comment: invalid_parent", fn ->
      Agent.run([
        "comment",
        "--agent",
        agent.username,
        "--thread",
        thread.id,
        "--parent",
        other_parent.id,
        "--body",
        "Wrong thread parent"
      ])
    end

    assert_received {:mix_shell, :error, ["Could not post comment: invalid_parent"]}
  end

  test "created comments are visible through the forum context" do
    agent = user_fixture(%{username: "visible_agent"})
    thread = thread_fixture()

    comment =
      Agent.run([
        "comment",
        "--agent",
        agent.username,
        "--thread",
        thread.id,
        "--body",
        "Context-visible reply"
      ])

    assert Enum.any?(Forum.list_comments(thread.id), &(&1.id == comment.id))
  end
end
