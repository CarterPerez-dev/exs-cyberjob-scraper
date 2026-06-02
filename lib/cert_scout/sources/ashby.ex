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
  alias CertScout.Log
  alias CertScout.Posting

  @impl true
  def label, do: "ashby"

  @impl true
  def collect(%Config{ashby_orgs: nil}) do
    Log.step("ashby: no orgs configured; pass --ashby-file lists/ashby_orgs.txt (one org per line)")
    %{scanned: 0, postings: []}
  end

  def collect(%Config{} = config) do
    Fetcher.collect(config.ashby_orgs, "ashby", config, &fetch_org(&1, config))
  end

  defp fetch_org(org, config) do
    url = "https://api.ashbyhq.com/posting-api/job-board/#{org}?includeCompensation=false"

    case HTTP.get_json(url, config) do
      {:ok, %{"jobs" => jobs}} when is_list(jobs) ->
        postings =
          jobs
          |> Enum.filter(&Cyber.keep?(&1["title"], config))
          |> Enum.map(&posting(&1, org))

        %{scanned: length(jobs), postings: postings}

      _ ->
        %{scanned: 0, postings: []}
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
