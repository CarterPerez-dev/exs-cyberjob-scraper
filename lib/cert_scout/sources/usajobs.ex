# © AngelaMos | 2026
# usajobs.ex

defmodule CertScout.Sources.USAJobs do
  @moduledoc """
  USAJobs federal search API. Requires a free API key: set `USAJOBS_API_KEY` and
  `USAJOBS_EMAIL`. Federal and DoD postings are the richest cert source because
  8570/8140 mandates them by name, so this is the recommended source when a key is
  available. Paginates by `SearchResultCountAll`.
  """

  @behaviour CertScout.Source

  alias CertScout.Config
  alias CertScout.HTTP
  alias CertScout.Log
  alias CertScout.Posting

  @page_size 500

  @impl true
  def label, do: "usajobs"

  @impl true
  def collect(%Config{usajobs: nil}) do
    Log.step("usajobs: skipped (set USAJOBS_API_KEY and USAJOBS_EMAIL)")
    %{scanned: 0, postings: []}
  end

  def collect(%Config{usajobs: creds} = config) do
    postings =
      config.search_terms
      |> Enum.flat_map(&collect_term(&1, creds, config))
      |> Enum.uniq_by(& &1.id)
      |> Enum.take(config.per_source_cap)

    %{scanned: length(postings), postings: postings}
  end

  defp collect_term(term, creds, config) do
    Enum.reduce_while(1..40, [], fn page, acc ->
      url =
        "https://data.usajobs.gov/api/search?Keyword=#{URI.encode(term)}&ResultsPerPage=#{@page_size}&Page=#{page}"

      case HTTP.get_json(url, config, headers(creds)) do
        {:ok, %{"SearchResult" => %{"SearchResultItems" => items}}} when items != [] ->
          acc = acc ++ Enum.map(items, &posting/1)
          Log.progress("usajobs", length(acc), config.per_source_cap)
          if length(items) < @page_size, do: {:halt, acc}, else: {:cont, acc}

        _ ->
          {:halt, acc}
      end
    end)
  end

  defp headers(%{key: key, email: email}) do
    [{"authorization-key", key}, {"user-agent", email}, {"host", "data.usajobs.gov"}]
  end

  defp posting(item) do
    d = item["MatchedObjectDescriptor"] || %{}
    details = get_in(d, ["UserArea", "Details"]) || %{}

    text =
      [details["JobSummary"], details["MajorDuties"], details["QualificationSummary"]]
      |> List.flatten()
      |> Enum.map_join(" ", &to_string/1)

    %Posting{
      id: "usajobs:#{item["MatchedObjectId"]}",
      source: "usajobs",
      company: d["OrganizationName"],
      title: d["PositionTitle"] || "",
      location: d["PositionLocationDisplay"],
      url: d["PositionURI"],
      text: text
    }
  end
end
