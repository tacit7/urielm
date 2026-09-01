defmodule Mix.Tasks.Forum.Agent do
  @moduledoc """
  Internal CLI for service users and agents to inspect and post forum content.

      mix forum.agent show THREAD_ID [--json]
      mix forum.agent inbox --agent USERNAME [--unread] [--limit 20] [--mark-read]
      mix forum.agent thread --agent USERNAME --board BOARD_SLUG --title TITLE --body BODY [--created-at ISO8601]
      mix forum.agent comment --agent USERNAME --thread THREAD_ID --body BODY [--created-at ISO8601]
      mix forum.agent reply --agent USERNAME --thread THREAD_ID --parent COMMENT_ID --body BODY [--created-at ISO8601]

  Use `--agent-id USER_ID` instead of `--agent USERNAME` when scripts should bind to
  a stable database ID. Use `--body-file PATH` for markdown or longer generated text.
  """

  use Mix.Task

  alias Urielm.Accounts
  alias Urielm.Forum
  alias Urielm.Forum.{Comment, Thread}
  alias Urielm.Repo

  @shortdoc "Lets internal agents inspect and post forum threads/comments"
  @requirements ["app.config"]

  @impl Mix.Task
  def run(args) do
    {opts, positional, invalid} =
      OptionParser.parse(args,
        strict: [
          agent: :string,
          agent_id: :integer,
          board: :string,
          board_id: :string,
          thread: :string,
          parent: :string,
          title: :string,
          slug: :string,
          kind: :string,
          body: :string,
          body_file: :string,
          unread: :boolean,
          mark_read: :boolean,
          limit: :integer,
          created_at: :string,
          json: :boolean
        ],
        aliases: [a: :agent, b: :board, t: :thread, p: :parent]
      )

    if invalid != [] do
      fail!(usage())
    end

    start_dependencies!()
    dispatch(positional, opts)
  end

  defp dispatch(["show", thread_id], opts) do
    thread = Forum.get_thread!(thread_id, include_comments?: true)

    if opts[:json] do
      Mix.shell().info(Jason.encode!(thread_payload(thread)))
    else
      Mix.shell().info(format_thread(thread))
    end

    thread
  end

  defp dispatch(["inbox"], opts) do
    agent = agent_user!(opts)
    limit = Keyword.get(opts, :limit, 20)

    if limit < 1 do
      fail!("--limit must be greater than 0")
    end

    notifications =
      Forum.list_notifications(agent.id,
        unread_only: Keyword.get(opts, :unread, false),
        limit: limit
      )

    unread_count = Forum.count_unread_notifications(agent.id)

    if opts[:json] do
      Mix.shell().info(
        Jason.encode!(%{
          agent: agent_summary(agent),
          unread_count: unread_count,
          notifications: Enum.map(notifications, &notification_summary/1)
        })
      )
    else
      Mix.shell().info(format_inbox(agent, unread_count, notifications))
    end

    if opts[:mark_read] do
      Forum.mark_all_notifications_as_read(agent.id)
    end

    notifications
  end

  defp dispatch(["thread"], opts) do
    agent = agent_user!(opts)
    board = board!(opts)
    title = required_option!(opts, :title, "--title is required")
    body = body!(opts)
    slug = opts[:slug] || Urielm.Slugify.slugify(title)

    attrs = %{
      "title" => title,
      "slug" => slug,
      "body" => body,
      "kind" => Keyword.get(opts, :kind, "forum")
    }

    case Forum.create_thread(board.id, agent.id, attrs) do
      {:ok, %Thread{} = thread} ->
        thread = maybe_backdate_post!(thread, opts)

        if opts[:json] do
          Mix.shell().info(Jason.encode!(%{thread: thread_summary(thread)}))
        else
          Mix.shell().info("""
          Created thread:
          ID: #{thread.id}
          Title: #{thread.title}
          Created at: #{thread.inserted_at}
          URL: #{thread_path(thread)}
          """)
        end

        thread

      {:error, reason} ->
        fail!("Could not create thread: #{format_error(reason)}")
    end
  end

  defp dispatch([command], opts) when command in ["comment", "reply"] do
    agent = agent_user!(opts)
    thread_id = required_option!(opts, :thread, "--thread is required")
    body = body!(opts)

    attrs =
      %{"body" => body}
      |> maybe_put("parent_id", opts[:parent])

    case Forum.create_comment(thread_id, agent.id, attrs) do
      {:ok, %Comment{} = comment} ->
        comment = maybe_backdate_post!(comment, opts)

        if opts[:json] do
          Mix.shell().info(Jason.encode!(%{comment: comment_summary(comment)}))
        else
          Mix.shell().info("""
          Posted comment:
          ID: #{comment.id}
          Thread: #{comment.thread_id}
          Parent: #{comment.parent_id || "none"}
          Created at: #{comment.inserted_at}
          URL: #{thread_path(comment.thread_id)}
          """)
        end

        comment

      {:error, reason} ->
        fail!("Could not post comment: #{format_error(reason)}")
    end
  end

  defp dispatch(_positional, _opts), do: fail!(usage())

  defp agent_user!(opts) do
    cond do
      opts[:agent_id] ->
        case Accounts.get_user(opts[:agent_id]) do
          nil -> fail!("Agent user not found: #{opts[:agent_id]}")
          user -> user
        end

      opts[:agent] ->
        case Accounts.get_user_by_username(opts[:agent]) do
          nil -> fail!("Agent user not found: #{opts[:agent]}")
          user -> user
        end

      true ->
        fail!("--agent or --agent-id is required")
    end
  end

  defp board!(opts) do
    cond do
      opts[:board_id] ->
        case Repo.get(Urielm.Forum.Board, opts[:board_id]) do
          nil -> fail!("Board not found: #{opts[:board_id]}")
          board -> board
        end

      opts[:board] ->
        case Forum.get_board(opts[:board]) do
          nil -> fail!("Board not found: #{opts[:board]}")
          board -> board
        end

      true ->
        fail!("--board or --board-id is required")
    end
  end

  defp body!(opts) do
    cond do
      opts[:body_file] && opts[:body] ->
        fail!("Use --body or --body-file, not both")

      opts[:body_file] ->
        case File.read(opts[:body_file]) do
          {:ok, body} -> body
          {:error, reason} -> fail!("Could not read body file: #{:file.format_error(reason)}")
        end

      opts[:body] ->
        opts[:body]

      true ->
        fail!("--body or --body-file is required")
    end
  end

  defp required_option!(opts, key, message) do
    case Keyword.get(opts, key) do
      nil -> fail!(message)
      value -> value
    end
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp thread_payload(%Thread{} = thread) do
    %{
      thread: thread_summary(thread),
      comments: Enum.map(thread.comments || [], &comment_summary/1)
    }
  end

  defp thread_summary(%Thread{} = thread) do
    %{
      id: thread.id,
      title: thread.title,
      slug: thread.slug,
      body: thread.body,
      board_id: thread.board_id,
      board_slug: assoc_field(thread.board, :slug),
      author_id: thread.author_id,
      author_username: assoc_field(thread.author, :username),
      comment_count: thread.comment_count,
      inserted_at: thread.inserted_at,
      url: thread_path(thread)
    }
  end

  defp comment_summary(%Comment{} = comment) do
    %{
      id: comment.id,
      thread_id: comment.thread_id,
      parent_id: comment.parent_id,
      author_id: comment.author_id,
      author_username: assoc_field(comment.author, :username),
      body: comment.body,
      inserted_at: comment.inserted_at
    }
  end

  defp notification_summary(notification) do
    %{
      id: notification.id,
      subject_type: notification.subject_type,
      subject_id: notification.subject_id,
      message: notification.message,
      read_at: notification.read_at,
      thread_id: notification.thread_id,
      thread_title: assoc_field(notification.thread, :title),
      actor_id: notification.actor_id,
      actor_username: assoc_field(notification.actor, :username),
      inserted_at: notification.inserted_at,
      url: notification.thread_id && thread_path(notification.thread_id)
    }
  end

  defp agent_summary(agent) do
    %{
      id: agent.id,
      username: agent.username,
      display_name: agent.display_name
    }
  end

  defp assoc_field(%Ecto.Association.NotLoaded{}, _field), do: nil
  defp assoc_field(nil, _field), do: nil
  defp assoc_field(struct, field), do: Map.get(struct, field)

  defp maybe_backdate_post!(post, opts) do
    case Keyword.get(opts, :created_at) do
      nil ->
        post

      created_at ->
        timestamp = parse_created_at!(created_at)

        post
        |> Ecto.Changeset.change(%{inserted_at: timestamp, updated_at: timestamp})
        |> Repo.update!()
    end
  end

  defp parse_created_at!(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} ->
        %{
          DateTime.truncate(datetime, :microsecond)
          | microsecond: {datetime.microsecond |> elem(0), 6}
        }

      {:error, _reason} ->
        fail!("--created-at must be an ISO8601 datetime with timezone, e.g. 2026-08-31T12:34:56Z")
    end
  end

  defp format_thread(%Thread{} = thread) do
    comments = thread.comments || []

    comments_text =
      if comments == [] do
        "No replies yet."
      else
        Enum.map_join(comments, "\n\n", &format_comment/1)
      end

    """
    Thread:
    ID: #{thread.id}
    Title: #{thread.title}
    Author: #{assoc_field(thread.author, :username) || thread.author_id}
    Board: #{assoc_field(thread.board, :slug) || thread.board_id}
    URL: #{thread_path(thread)}

    Body:
    #{thread.body}

    Replies:
    #{comments_text}
    """
  end

  defp format_inbox(agent, unread_count, notifications) do
    notification_text =
      if notifications == [] do
        "No notifications."
      else
        Enum.map_join(notifications, "\n\n", &format_notification/1)
      end

    """
    Inbox:
    Agent: #{agent.username || agent.id}
    Unread: #{unread_count}

    Notifications:
    #{notification_text}
    """
  end

  defp format_notification(notification) do
    """
    - ID: #{notification.id}
      Type: #{notification.subject_type}
      Read: #{if(notification.read_at, do: "yes", else: "no")}
      Actor: #{assoc_field(notification.actor, :username) || notification.actor_id || "system"}
      Thread: #{assoc_field(notification.thread, :title) || notification.thread_id || "none"}
      Thread ID: #{notification.thread_id || "none"}
      URL: #{if(notification.thread_id, do: thread_path(notification.thread_id), else: "none")}
      Message: #{notification.message || ""}
    """
    |> String.trim()
  end

  defp format_comment(%Comment{} = comment) do
    """
    - ID: #{comment.id}
      Parent: #{comment.parent_id || "none"}
      Author: #{assoc_field(comment.author, :username) || comment.author_id}
      Body: #{comment.body}
    """
    |> String.trim()
  end

  defp thread_path(%Thread{id: id}), do: thread_path(id)
  defp thread_path(thread_id), do: "/forum/t/#{thread_id}"

  defp start_dependencies! do
    [:postgrex, :ecto_sql, :jason]
    |> Enum.each(fn app ->
      case Application.ensure_all_started(app) do
        {:ok, _apps} -> :ok
        {:error, reason} -> fail!("Could not start #{app}: #{inspect(reason)}")
      end
    end)

    case Repo.start_link() do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
      {:error, reason} -> fail!("Could not start repo: #{inspect(reason)}")
    end
  end

  defp format_error(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> inspect()
  end

  defp format_error(reason) when is_atom(reason), do: reason |> Atom.to_string()
  defp format_error(reason), do: inspect(reason)

  defp usage do
    """
    Usage:
      mix forum.agent show THREAD_ID [--json]
      mix forum.agent inbox --agent USERNAME [--unread] [--limit 20] [--mark-read] [--json]
      mix forum.agent thread --agent USERNAME --board BOARD_SLUG --title TITLE (--body BODY | --body-file PATH) [--created-at ISO8601] [--json]
      mix forum.agent comment --agent USERNAME --thread THREAD_ID (--body BODY | --body-file PATH) [--parent COMMENT_ID] [--created-at ISO8601] [--json]
      mix forum.agent reply --agent USERNAME --thread THREAD_ID --parent COMMENT_ID (--body BODY | --body-file PATH) [--created-at ISO8601] [--json]
    """
    |> String.trim()
  end

  defp fail!(message) do
    Mix.shell().error(message)
    Mix.raise(message)
  end
end
