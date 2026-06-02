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
  alias CertScout.Cyber
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
    Fetcher.collect(orgs, "ashby", config, &fetch_org(&1, config))
  end

  defp fetch_org(org, config) do
    url = "https://api.ashbyhq.com/posting-api/job-board/#{org}?includeCompensation=false"

    case HTTP.get_json(url, config) do
      {:ok, %{"jobs" => jobs}} when is_list(jobs) ->
        postings =
          jobs
          |> Enum.filter(&keep?(&1["title"], config))
          |> Enum.map(&posting(&1, org))

        %{scanned: length(jobs), postings: postings}

      _ ->
        %{scanned: 0, postings: []}
    end
  end

  defp keep?(title, %Config{include_all: true}) when is_binary(title), do: title != ""
  defp keep?(title, _config) when is_binary(title), do: Cyber.match?(title)
  defp keep?(_title, _config), do: false

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
