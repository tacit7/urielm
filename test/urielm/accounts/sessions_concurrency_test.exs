defmodule Urielm.Accounts.SessionsConcurrencyTest do
  # Shared Sandbox ownership serializes queries on one connection. This test
  # commits its own fixture and gives each contender a separate connection.
  use ExUnit.Case, async: false

  import Ecto.Query
  alias Ecto.Adapters.SQL.Sandbox
  alias Urielm.Accounts.{Sessions, User, UserSession}
  alias Urielm.Repo

  @wait_timeout 5_000

  test "concurrent signup consumers return the user exactly once" do
    email = "signup-race-#{Ecto.UUID.generate()}@example.test"

    # Register cleanup before committing anything, including partial setup.
    on_exit(fn ->
      Sandbox.unboxed_run(Repo, fn ->
        Repo.transaction(fn ->
          user_ids = from(u in User, where: u.email == ^email, select: u.id)
          Repo.delete_all(from(s in UserSession, where: s.user_id in subquery(user_ids)))
          Repo.delete_all(from(u in User, where: u.email == ^email))
        end)
      end)
    end)

    assert :ok = Sandbox.checkout(Repo, sandbox: false)
    user = Repo.insert!(%User{email: email, password_hash: "signup-race-test-credential"})
    grant = Sessions.create(user, "signup")
    {_, session} = Sessions.fetch(grant, "signup")
    parent_backend = backend_pid()
    parent = self()
    barrier = make_ref()
    supervisor = start_supervised!(Task.Supervisor)

    tasks =
      for _ <- 1..2 do
        Task.Supervisor.async_nolink(supervisor, fn ->
          assert :ok = Sandbox.checkout(Repo, sandbox: false)

          try do
            send(parent, {barrier, :ready, self(), backend_pid()})

            receive do
              {^barrier, :start} -> Sessions.consume_signup(grant)
            after
              @wait_timeout -> flunk("signup consumer did not receive the start signal")
            end
          after
            Sandbox.checkin(Repo)
          end
        end)
      end

    try do
      backends =
        Enum.map(tasks, fn task ->
          pid = task.pid
          assert_receive {^barrier, :ready, ^pid, backend}, @wait_timeout
          backend
        end)

      assert length(Enum.uniq([parent_backend | backends])) == 3

      assert {:ok, :contended} =
               Repo.transaction(fn ->
                 Repo.one!(from(s in UserSession, where: s.id == ^session.id, lock: "FOR UPDATE"))
                 Enum.each(tasks, &send(&1.pid, {barrier, :start}))

                 # Both SELECTs can read the committed grant while this lock
                 # blocks DELETEs. Do not release it until both backends are
                 # waiting: this forces the losing caller's delete-count path.
                 deadline = System.monotonic_time(:millisecond) + @wait_timeout
                 await_blocked_consumers(backends, deadline)
                 :contended
               end)

      results = Enum.map(tasks, &Task.await(&1, @wait_timeout))
      assert Enum.count(results, &is_nil/1) == 1
      assert [%User{id: user_id}] = Enum.reject(results, &is_nil/1)
      assert user_id == user.id
      refute Repo.get(UserSession, session.id)
      assert Sessions.consume_signup(grant) == nil
    after
      Enum.each(tasks, &Task.shutdown(&1, :brutal_kill))
      Sandbox.checkin(Repo)
    end
  end

  defp backend_pid do
    %{rows: [[pid]]} = Repo.query!("SELECT pg_backend_pid()")
    pid
  end

  defp await_blocked_consumers(backends, deadline) do
    %{rows: [[blocked]]} =
      Repo.query!(
        "SELECT count(*) FROM pg_stat_activity " <>
          "WHERE pid = ANY($1::int[]) AND cardinality(pg_blocking_pids(pid)) > 0",
        [backends]
      )

    cond do
      blocked == 2 ->
        :ok

      System.monotonic_time(:millisecond) < deadline ->
        Process.sleep(10)
        await_blocked_consumers(backends, deadline)

      true ->
        flunk("both signup consumers did not contend for the locked grant")
    end
  end
end
