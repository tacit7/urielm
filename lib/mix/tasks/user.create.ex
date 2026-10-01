defmodule Mix.Tasks.User.Create do
  @moduledoc """
  Create a user account.

      mix user.create --email EMAIL --username USERNAME --display-name NAME --password PASSWORD
  """

  use Mix.Task

  alias Urielm.Accounts

  @shortdoc "Creates a user account"
  @requirements ["app.config"]

  @impl Mix.Task
  def run(args) do
    {opts, _positional, _invalid} =
      OptionParser.parse(args,
        strict: [
          email: :string,
          username: :string,
          display_name: :string,
          password: :string
        ]
      )

    start_dependencies!()

    email = required!(opts, :email, "--email is required")
    username = required!(opts, :username, "--username is required")
    display_name = required!(opts, :display_name, "--display-name is required")
    password = required!(opts, :password, "--password is required")

    case Accounts.get_user_by_email(email) do
      nil ->
        case Accounts.register_user(%{
               email: email,
               username: username,
               display_name: display_name,
               password: password
             }) do
          {:ok, user} ->
            Mix.shell().info("""
            ✓ Created user account:
            ID: #{user.id}
            Email: #{user.email}
            Username: #{user.username}
            Display Name: #{user.display_name}
            """)

            user

          {:error, changeset} ->
            fail!("Could not create user: #{format_error(changeset)}")
        end

      user ->
        Mix.shell().info("""
        User already exists:
        ID: #{user.id}
        Email: #{user.email}
        Username: #{user.username}
        Display Name: #{user.display_name}
        """)

        user
    end
  end

  defp required!(opts, key, message) do
    case Keyword.get(opts, key) do
      nil -> fail!(message)
      value -> value
    end
  end

  defp start_dependencies! do
    # Start the full application
    case Application.ensure_all_started(:urielm) do
      {:ok, _apps} -> :ok
      {:error, reason} -> fail!("Could not start :urielm: #{inspect(reason)}")
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

  defp format_error(reason), do: inspect(reason)

  defp fail!(message) do
    Mix.shell().error(message)
    Mix.raise(message)
  end
end
