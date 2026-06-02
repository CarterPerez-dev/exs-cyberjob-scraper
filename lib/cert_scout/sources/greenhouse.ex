# © AngelaMos | 2026
# greenhouse.ex

defmodule CertScout.Sources.Greenhouse do
  @moduledoc """
  Greenhouse public job boards. `?content=true` returns every posting for a
  company board, with the full HTML description, in a single request, so one HTTP
  call yields hundreds of postings. The bundled board list is hand-verified to
  return jobs; override it with `--boards-file`.
  """

  @behaviour CertScout.Source

  alias CertScout.Config
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
    waymo verkada checkr
  )

  @impl true
  def label, do: "greenhouse"

  @impl true
  def collect(%Config{} = config) do
    boards = config.boards || @boards
    Fetcher.run(boards, "greenhouse", config, &fetch_board(&1, config))
  end

  defp fetch_board(token, config) do
    url = "https://boards-api.greenhouse.io/v1/boards/#{token}/jobs?content=true"

    case HTTP.get_json(url, config) do
      {:ok, %{"jobs" => jobs}} when is_list(jobs) -> Enum.map(jobs, &posting(&1, token))
      _ -> []
    end
  end

  defp posting(job, token) do
    %Posting{
      id: "greenhouse:#{token}:#{job["id"]}",
      source: "greenhouse",
      company: token,
      title: job["title"] || "",
      location: get_in(job, ["location", "name"]),
      url: job["absolute_url"],
      text: Html.to_text(job["content"])
    }
  end
end
