# © AngelaMos | 2026
# http.ex

defmodule CertScout.HTTP do
  @moduledoc """
  Thin wrapper over Req. Centralizes the polite-scraping policy: a real
  user-agent, an optional per-request jitter delay, capped receive timeouts, and
  `retry: :transient` which gives exponential backoff on 429s and 5xx without
  letting one bad request kill the run. Response bodies are decoded with the
  built-in `JSON` module rather than a third-party encoder.
  """

  alias CertScout.Config

  @spec get_json(String.t(), Config.t(), keyword()) :: {:ok, term()} | {:error, term()}
  def get_json(url, %Config{} = config, headers \\ []) do
    request(config,
      url: url,
      method: :get,
      headers: base_headers(config) ++ headers
    )
  end

  @spec post_json(String.t(), map(), Config.t(), keyword()) :: {:ok, term()} | {:error, term()}
  def post_json(url, body, %Config{} = config, headers \\ []) do
    request(config,
      url: url,
      method: :post,
      headers: base_headers(config) ++ [{"content-type", "application/json"}] ++ headers,
      body: JSON.encode!(body)
    )
  end

  defp request(%Config{} = config, opts) do
    throttle(config)

    options =
      Keyword.merge(opts,
        decode_body: false,
        retry: :transient,
        max_retries: 4,
        retry_log_level: false,
        connect_options: [timeout: 15_000],
        receive_timeout: config.timeout_ms
      )

    case Req.request(options) do
      {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
        decode(body)

      {:ok, %Req.Response{status: status}} ->
        {:error, {:http_status, status}}

      {:error, reason} ->
        {:error, reason}
    end
  rescue
    error -> {:error, error}
  end

  defp decode(""), do: {:ok, nil}

  defp decode(body) when is_binary(body) do
    case JSON.decode(body) do
      {:ok, decoded} -> {:ok, decoded}
      {:error, reason} -> {:error, {:json, reason}}
    end
  end

  defp decode(body), do: {:ok, body}

  defp base_headers(%Config{user_agent: ua}) do
    [{"user-agent", ua}, {"accept", "application/json"}]
  end

  defp throttle(%Config{delay_ms: ms}) when is_integer(ms) and ms > 0 do
    Process.sleep(:rand.uniform(ms))
  end

  defp throttle(_), do: :ok
end
