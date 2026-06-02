# © AngelaMos | 2026
# ashby.ex

defmodule CertScout.Sources.Ashby do
  @moduledoc """
  Ashby public job boards via the posting API, which returns every posting for an
  organization with `descriptionPlain` in one request. Override the org list with
  `--ashby-file`.
  """

  @behaviour CertScout.Source

  alias CertScout.Config
  alias CertScout.Fetcher
  alias CertScout.Html
  alias CertScout.HTTP
  alias CertScout.Posting

  @orgs ~w()

  @impl true
  def label, do: "ashby"

  @impl true
  def collect(%Config{} = config) do
    orgs = config.ashby_orgs || @orgs
    Fetcher.run(orgs, "ashby", config, &fetch_org(&1, config))
  end

  defp fetch_org(org, config) do
    url = "https://api.ashbyhq.com/posting-api/job-board/#{org}?includeCompensation=false"

    case HTTP.get_json(url, config) do
      {:ok, %{"jobs" => jobs}} when is_list(jobs) -> Enum.map(jobs, &posting(&1, org))
      _ -> []
    end
  end

  defp posting(job, org) do
    %Posting{
      id: "ashby:#{org}:#{job["id"]}",
      source: "ashby",
      company: org,
      title: job["title"] || "",
      location: job["location"],
      url: job["jobUrl"],
      text: job["descriptionPlain"] || Html.to_text(job["descriptionHtml"])
    }
  end
end
