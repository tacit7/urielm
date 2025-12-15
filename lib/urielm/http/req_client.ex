defmodule Urielm.HTTP.ReqClient do
  @compile {:no_warn_undefined, Req}
  @compile {:no_warn_undefined, Req.Request}
  @moduledoc """
  Thin, opinionated wrapper around Req providing:

    * Consistent base client (base_url, timeouts, headers)
    * Standard retry/backoff for idempotent requests only
    * Telemetry around every request

  Default policy (may be overridden per-call):

    * Retries: 3 attempts (initial try + up to 2 retries) for idempotent methods
    * Backoff: jittered 200–500ms between retries
    * No retries for non-idempotent writes (POST that creates, PATCH with side effects),
      auth endpoints, or anything with external side effects

  """
    @type method :: :get | :head | :options | :trace | :delete | :put | :post | :patch

  @default_timeout 5_000
  @default_connect_timeout 5_000
  @default_max_retries 3

  @doc """
  Builds a base Req client with standard configuration.

  Options:
    * :base_url - override base URL (defaults to System.get_env("API_URL") if present)
    * :headers - default headers map
    * :timeout - request timeout (ms)
    * :connect_timeout - connect timeout (ms)
  """
  def new(opts \\ []) do
    base_url = opts[:base_url] || System.get_env("API_URL")
    timeout = opts[:timeout] || @default_timeout
    connect_timeout = opts[:connect_timeout] || @default_connect_timeout

    client =
      Req.new()
      |> Req.merge(put_timeout: timeout, connect_options: [timeout: connect_timeout])

    client = if base_url, do: Req.merge(client, base_url: base_url), else: client
    client = if headers = opts[:headers], do: Req.merge(client, headers: headers), else: client

    client
  end

  @doc """
  Perform an HTTP request.

  Options (merged into Req):
    * :headers, :params, :body, :json, etc. (see Req docs)

  Retry controls:
    * :retry? - boolean (default: true only if method is idempotent)
    * :max_retries - integer (default: #{@default_max_retries})
    * :retry_exempt? - boolean (force-disable retry regardless of method)

  Telemetry:
    * Emits [:external, :req, :request] before, [:external, :req, :response] after
  """
  def request(client, method, url, opts \\ []) when is_atom(method) do
    {retry?, max_retries} = retry_config(method, opts)

    meta = %{
      method: method,
      url: to_string(url),
      retry?: retry?,
      max_retries: max_retries
    }

    :telemetry.execute([:external, :req, :request], %{}, meta)
    t0 = System.monotonic_time(:millisecond)

    result = do_request_with_retries(client, method, url, opts, retry?, max_retries)

    duration = System.monotonic_time(:millisecond) - t0

    case result do
      {:ok, resp} ->
        status = Map.get(resp, :status)
        :telemetry.execute([:external, :req, :response], %{duration: duration}, Map.merge(meta, %{status: status}))
        result

      {:error, reason} ->
        :telemetry.execute([:external, :req, :response], %{duration: duration}, Map.put(meta, :error, inspect(reason)))
        result
    end
  end

  def get(client, url, opts \\ []), do: request(client, :get, url, opts)
  def head(client, url, opts \\ []), do: request(client, :head, url, opts)
  def options(client, url, opts \\ []), do: request(client, :options, url, opts)
  def trace(client, url, opts \\ []), do: request(client, :trace, url, opts)
  def delete(client, url, opts \\ []), do: request(client, :delete, url, opts)
  def put(client, url, opts \\ []), do: request(client, :put, url, opts)
  def post(client, url, opts \\ []), do: request(client, :post, url, opts)
  def patch(client, url, opts \\ []), do: request(client, :patch, url, opts)

  # --- internal

  defp retry_config(method, opts) do
    exempt? = opts[:retry_exempt?]
    max_retries = opts[:max_retries] || @default_max_retries

    retry? =
      cond do
        exempt? -> false
        opts[:retry?] == true -> true
        opts[:retry?] == false -> false
        idempotent?(method) -> true
        true -> false
      end

    {retry?, max_retries}
  end

  defp idempotent?(method) when method in [:get, :head, :options, :trace, :put, :delete], do: true
  defp idempotent?(_), do: false

  defp do_request_with_retries(client, method, url, opts, false, _max), do: run_once(client, method, url, opts)

  defp do_request_with_retries(client, method, url, opts, true, max) do
    attempt(client, method, url, opts, max)
  end

  defp attempt(client, method, url, opts, remaining) do
    case run_once(client, method, url, opts) do
      {:ok, resp} = ok ->
        status = Map.get(resp, :status)
        if retriable_status?(status) and remaining > 1 do
          backoff_jitter()
          attempt(client, method, url, opts, remaining - 1)
        else
          ok
        end

      {:error, _} = err ->
        if remaining > 1 do
          backoff_jitter()
          attempt(client, method, url, opts, remaining - 1)
        else
          err
        end
    end
  end

  defp retriable_status?(status) when status in 500..599, do: true
  defp retriable_status?(429), do: true
  defp retriable_status?(_), do: false

  defp backoff_jitter() do
    # ~200–500ms jitter
    :timer.sleep(200 + :rand.uniform(301) - 1)
  end

  defp run_once(client, method, url, opts) do
    req = if is_struct(client, Req.Request), do: client, else: new(client || [])

    case method do
      :get -> Req.get(req, Keyword.merge([url: url], opts))
      :head -> Req.head(req, Keyword.merge([url: url], opts))
      :options -> Req.options(req, Keyword.merge([url: url], opts))
      :trace -> Req.trace(req, Keyword.merge([url: url], opts))
      :delete -> Req.delete(req, Keyword.merge([url: url], opts))
      :put -> Req.put(req, Keyword.merge([url: url], opts))
      :post -> Req.post(req, Keyword.merge([url: url], opts))
      :patch -> Req.patch(req, Keyword.merge([url: url], opts))
    end
  end
end
