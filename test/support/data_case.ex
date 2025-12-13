defmodule Urielm.DataCase do
  @moduledoc """
  This module defines the setup for model tests requiring
  interaction with the database.

  You may define functions here to be used as helpers in
  your model tests. See `errors_on/2`'s doc as an example.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use Urielm.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Urielm.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Urielm.DataCase
    end
  end

  setup tags do
    Urielm.DataCase.setup_sandbox(tags)
    :ok
  end

  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Urielm.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{})
      assert "can't be blank" in errors_on(changeset).email
  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}/", message, fn _, key ->
        opts |> Keyword.get(String.to_atom(key)) |> to_string()
      end)
    end)
  end
end
