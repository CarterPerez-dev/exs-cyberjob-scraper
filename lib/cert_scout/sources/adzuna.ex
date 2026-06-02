# © AngelaMos | 2026
# adzuna.ex

defmodule CertScout.Sources.Adzuna do
  @moduledoc """
  Adzuna market-wide search API. Requires a free key: set `ADZUNA_APP_ID` and
  `ADZUNA_APP_KEY`. Aggregates postings across the whole market for a keyword, so
  it reaches the highest raw volume of any source; descriptions are summaries, not
  full text. Country defaults to `us` and is set with `--country`.
  """

  @behaviour CertScout.Source

  alias CertScout.Config
  alias CertScout.HTTP
  alias CertScout.Log
  alias CertScout.Posting

  @page_size 50

  @impl true
  def label, do: "adzuna"

  @impl true
  def collect(%Config{adzuna: nil}) do
    Log.step("adzuna: skipped (set ADZUNA_APP_ID and ADZUNA_APP_KEY)")
    []
  end

  def collect(%Config{adzuna: creds} = config) do
    config.search_terms
    |> Enum.flat_map(&collect_term(&1, creds, config))
    |> Enum.uniq_by(& &1.id)
    |> Enum.take(config.per_source_cap)
  end

  defp collect_term(term, creds, config) do
    Enum.reduce_while(1..40, [], fn page, acc ->
      url =
        "https://api.adzuna.com/v1/api/jobs/#{config.country}/search/#{page}" <>
          "?app_id=#{creds.app_id}&app_key=#{creds.app_key}" <>
          "&results_per_page=#{@page_size}&what=#{URI.encode(term)}&content-type=application/json"

      case HTTP.get_json(url, config) do
        {:ok, %{"results" => results}} when results != [] ->
          acc = acc ++ Enum.map(results, &posting/1)
          Log.progress("adzuna", length(acc), config.per_source_cap)
          if length(results) < @page_size, do: {:halt, acc}, else: {:cont, acc}

        _ ->
          {:halt, acc}
      end
    end)
  end

  defp posting(job) do
    %Posting{
      id: "adzuna:#{job["id"]}",
      source: "adzuna",
      company: get_in(job, ["company", "display_name"]),
      title: job["title"] || "",
      location: get_in(job, ["location", "display_name"]),
      url: job["redirect_url"],
      text: job["description"] || ""
    }
  end
end
