# © AngelaMos | 2026
# cert_scout.ex

defmodule CertScout do
  @moduledoc """
  Orchestrates a run: collect postings from every configured source, dedupe,
  isolate the cybersecurity subset, analyze certification demand, then write the
  raw data and the report. Returns a summary map; all progress goes to stderr.
  """

  alias CertScout.Analyzer
  alias CertScout.Config
  alias CertScout.Cyber
  alias CertScout.Log
  alias CertScout.Logos
  alias CertScout.Posting
  alias CertScout.Report
  alias CertScout.Source
  alias CertScout.Storage

  @spec run(Config.t()) :: map()
  def run(%Config{} = config) do
    Log.info("CertScout starting | sources: #{Enum.join(config.sources, ", ")} | target: #{config.target}")

    {scanned, postings} =
      Enum.reduce(config.sources, {0, []}, fn key, {scanned_acc, postings_acc} ->
        %{scanned: scanned, postings: postings} = collect_source(key, config)
        {scanned_acc + scanned, postings_acc ++ postings}
      end)

    cyber =
      postings
      |> Enum.uniq_by(&Posting.dedup_key/1)
      |> Enum.filter(&Cyber.keep?(&1.title, config))
      |> cap(config.target)

    Log.info("Scanned #{scanned} postings | #{length(cyber)} cybersecurity roles | analyzing certifications")

    analysis = Analyzer.analyze(cyber, config.certs)
    meta = meta(scanned, cyber, config)

    persist(config, analysis, meta)
    summarize(analysis, meta)
  end

  defp collect_source(key, config) do
    case Source.module(key) do
      nil ->
        Log.step("unknown source: #{key}")
        %{scanned: 0, postings: []}

      module ->
        Log.info("Source: #{module.label()}")
        module.collect(config)
    end
  end

  defp cap(postings, target) when is_integer(target) and target > 0, do: Enum.take(postings, target)
  defp cap(postings, _target), do: postings

  defp meta(scanned, cyber, config) do
    companies =
      cyber
      |> Enum.map(& &1.company)
      |> Enum.reject(&(is_nil(&1) or &1 == ""))
      |> Enum.uniq()
      |> length()

    %{
      total_scraped: scanned,
      cyber_postings: length(cyber),
      companies: companies,
      sources: Enum.map(config.sources, &to_string/1),
      search_terms: config.search_terms,
      generated_on: Date.utc_today(),
      top_n: config.top_n
    }
  end

  defp persist(config, analysis, meta) do
    File.mkdir_p!(config.output_dir)
    top_certs = analysis.results |> Enum.take(config.top_n) |> Enum.map(& &1.cert)

    Log.info("Downloading #{length(top_certs)} certification logos")
    Logos.download_all(top_certs, Path.join(config.output_dir, "assets"), config)

    Storage.write(config.output_dir, analysis, meta)
    Report.write(config.output_dir, analysis, meta)
    Log.info("Wrote #{config.output_dir}/REPORT.md and #{config.output_dir}/data/")
  end

  defp summarize(analysis, meta) do
    %{
      total_scraped: meta.total_scraped,
      cyber_postings: meta.cyber_postings,
      companies: meta.companies,
      top:
        analysis.results
        |> Enum.take(meta.top_n)
        |> Enum.map(&%{name: &1.cert.name, postings: &1.count, percent: &1.percent})
    }
  end
end
