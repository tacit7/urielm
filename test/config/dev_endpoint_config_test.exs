defmodule Urielm.Config.DevEndpointConfigTest do
  use ExUnit.Case, async: false

  @dev_config "config/dev.exs"

  test "fixes dev startup when local HTTPS certs are missing" do
    previous_env = %{
      "DEV_HTTPS_CERTFILE" => System.get_env("DEV_HTTPS_CERTFILE"),
      "DEV_HTTPS_KEYFILE" => System.get_env("DEV_HTTPS_KEYFILE")
    }

    missing_path = Path.join(System.tmp_dir!(), "urielm-missing-dev-cert.pem")

    try do
      System.put_env("DEV_HTTPS_CERTFILE", missing_path)
      System.put_env("DEV_HTTPS_KEYFILE", missing_path)

      endpoint_config =
        @dev_config
        |> Config.Reader.read!()
        |> get_in([:urielm, UrielmWeb.Endpoint])

      refute Keyword.has_key?(endpoint_config, :https)
    after
      restore_env(previous_env)
    end
  end

  defp restore_env(env) do
    Enum.each(env, fn
      {key, nil} -> System.delete_env(key)
      {key, value} -> System.put_env(key, value)
    end)
  end
end
