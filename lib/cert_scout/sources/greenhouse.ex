# © AngelaMos | 2026
# greenhouse.ex

defmodule CertScout.Sources.Greenhouse do
  @moduledoc """
  Greenhouse public job boards. Two-phase so it scales to thousands of boards
  without downloading every description: list a board's jobs (titles only),
  isolate the cybersecurity titles, then fetch the full description only for
  those. The bundled board list is hand-verified; override it with `--boards-file`
  (one token per line) to point at the full ATS company set.
  """

  @behaviour CertScout.Source

  alias CertScout.Config
  alias CertScout.Cyber
  alias CertScout.Fetcher
  alias CertScout.Html
  alias CertScout.HTTP
  alias CertScout.Posting

  @boards ~w(
    stripe databricks datadog cloudflare gitlab dropbox instacart lyft pinterest
    reddit twitch discord figma robinhood brex samsara elastic mongodb okta
    netskope zscaler twilio asana airtable flexport gusto faire scaleai anthropic
    affirm chime sofi marqeta gemini betterment toast squarespace roblox riotgames
    scopely peloton oscar glossier calendly webflow mixpanel amplitude launchdarkly
    postman bugcrowd veracode abnormalsecurity yubico expel huntress dragos axonius
    chainguard fivetran clickhouse cockroachlabs planetscale adyen gocardless nuro
    waymo verkada checkr cribl tines sumologic recordedfuture tailscale vercel
    fastly starburst mercury monzo nubank
  )

  @impl true
  def label, do: "greenhouse"

  @impl true
  def collect(%Config{} = config) do
    boards = config.boards || @boards
    Fetcher.collect(boards, "greenhouse", config, &fetch_board(&1, config))
  end

  defp fetch_board(token, config) do
    case HTTP.get_json("https://boards-api.greenhouse.io/v1/boards/#{token}/jobs", config) do
      {:ok, %{"jobs" => jobs}} when is_list(jobs) ->
        postings =
          jobs
          |> Enum.filter(&Cyber.keep?(&1["title"], config))
          |> Enum.map(&detail(&1, token, config))
          |> Enum.reject(&is_nil/1)

        %{scanned: length(jobs), postings: postings}

      _ ->
        %{scanned: 0, postings: []}
    end
  end

  defp detail(job, token, config) do
    url = "https://boards-api.greenhouse.io/v1/boards/#{token}/jobs/#{job["id"]}"

    case HTTP.get_json(url, config) do
      {:ok, %{"content" => content} = full} -> posting(full, content, token)
      _ -> posting(job, "", token)
    end
  end

  defp posting(job, content, token) do
    %Posting{
      id: "greenhouse:#{token}:#{job["id"]}",
      source: "greenhouse",
      company: token,
      title: job["title"] || "",
      location: get_in(job, ["location", "name"]),
      url: job["absolute_url"],
      text: Html.to_text(content)
    }
  end
end
