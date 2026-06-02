# © AngelaMos | 2026
# config.ex

defmodule CertScout.Config do
  @moduledoc """
  Runtime configuration for a single scrape. Built once by the CLI from flags and
  environment variables, then threaded read-only through every source and stage.
  """

  alias CertScout.Certifications

  defstruct sources: [:workday, :greenhouse],
            search_terms: [
              "cybersecurity",
              "information security",
              "security engineer",
              "security analyst",
              "penetration testing"
            ],
            target: 12_000,
            top_n: 12,
            max_concurrency: 24,
            delay_ms: 25,
            timeout_ms: 25_000,
            per_source_cap: 6_000,
            include_all: false,
            country: "us",
            output_dir: "output",
            user_agent:
              "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36 CertScout/0.1",
            certs: nil,
            boards: nil,
            workday_sites: nil,
            lever_companies: nil,
            ashby_orgs: nil,
            usajobs: nil,
            adzuna: nil

  @type t :: %__MODULE__{}

  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    base = struct(__MODULE__, sanitize(opts))
    with_env_credentials(%{base | certs: base.certs || Certifications.default()})
  end

  defp sanitize(opts), do: Enum.reject(opts, fn {_k, v} -> is_nil(v) end)

  defp with_env_credentials(config) do
    config
    |> put_usajobs()
    |> put_adzuna()
  end

  defp put_usajobs(config) do
    key = System.get_env("USAJOBS_API_KEY")
    email = System.get_env("USAJOBS_EMAIL")

    if key && email do
      %{config | usajobs: %{key: key, email: email}}
    else
      config
    end
  end

  defp put_adzuna(config) do
    app_id = System.get_env("ADZUNA_APP_ID")
    app_key = System.get_env("ADZUNA_APP_KEY")

    if app_id && app_key do
      %{config | adzuna: %{app_id: app_id, app_key: app_key}}
    else
      config
    end
  end
end
