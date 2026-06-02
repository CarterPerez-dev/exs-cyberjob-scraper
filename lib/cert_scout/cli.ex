# © AngelaMos | 2026
# cli.ex

defmodule CertScout.CLI do
  @moduledoc """
  Command-line entry point. Parses flags into a Config, runs the scrape, and
  prints the final ranking to stdout (progress goes to stderr, so stdout can be
  piped). Works as an escript or via `mix run -e "CertScout.CLI.main(System.argv())"`.
  """

  alias CertScout.Certifications
  alias CertScout.Config
  alias CertScout.Source

  @switches [
    sources: :string,
    terms: :string,
    target: :string,
    top: :integer,
    concurrency: :integer,
    delay: :integer,
    output: :string,
    boards_file: :string,
    workday_file: :string,
    lever_file: :string,
    ashby_file: :string,
    certs_file: :string,
    country: :string,
    all: :boolean,
    help: :boolean
  ]

  @aliases [h: :help]

  @spec main([String.t()]) :: :ok
  def main(argv) do
    {opts, _rest, _invalid} = OptionParser.parse(argv, strict: @switches, aliases: @aliases)

    if opts[:help] do
      IO.puts(usage())
    else
      {:ok, _} = Application.ensure_all_started(:req)
      opts |> build_config() |> CertScout.run() |> print_summary()
    end

    :ok
  end

  defp build_config(opts) do
    [
      sources: parse_sources(opts[:sources]),
      search_terms: parse_list(opts[:terms]),
      target: parse_target(opts[:target]),
      top_n: opts[:top],
      max_concurrency: opts[:concurrency],
      delay_ms: opts[:delay],
      output_dir: opts[:output],
      include_all: opts[:all],
      country: opts[:country],
      boards: read_lines(opts[:boards_file]),
      lever_companies: read_lines(opts[:lever_file]),
      ashby_orgs: read_lines(opts[:ashby_file]),
      workday_sites: read_workday(opts[:workday_file]),
      certs: read_certs(opts[:certs_file])
    ]
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Config.new()
  end

  defp parse_sources(nil), do: nil

  defp parse_sources(string) do
    valid = Source.keys()

    string
    |> parse_list()
    |> Enum.map(&safe_atom/1)
    |> Enum.filter(&(&1 in valid))
  end

  defp safe_atom(string) do
    String.to_existing_atom(string)
  rescue
    ArgumentError -> nil
  end

  defp parse_list(nil), do: nil

  defp parse_list(string) do
    string
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp parse_target(nil), do: nil
  defp parse_target("all"), do: :all
  defp parse_target(string), do: String.to_integer(string)

  defp read_lines(nil), do: nil

  defp read_lines(path) do
    path
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == "" or String.starts_with?(&1, "#")))
  end

  defp read_workday(nil), do: nil

  defp read_workday(path) do
    path
    |> read_lines()
    |> Enum.map(fn line ->
      [tenant, dc, site] = line |> String.split(",") |> Enum.map(&String.trim/1)
      %{tenant: tenant, dc: dc, site: site}
    end)
  end

  defp read_certs(nil), do: nil
  defp read_certs(path), do: path |> File.read!() |> Certifications.from_json()

  defp print_summary(summary) do
    IO.puts("")
    IO.puts("CertScout results")
    IO.puts(String.duplicate("=", 60))
    IO.puts("Postings scanned : #{summary.total_scraped}")
    IO.puts("Cybersecurity    : #{summary.cyber_postings}")
    IO.puts("Employers        : #{summary.companies}")
    IO.puts(String.duplicate("-", 60))

    summary.top
    |> Enum.with_index(1)
    |> Enum.each(fn {row, rank} ->
      name = String.pad_trailing(row.name, 34)

      IO.puts(
        "#{String.pad_leading(to_string(rank), 2)}. #{name} #{String.pad_leading(to_string(row.postings), 5)}  #{row.percent}%"
      )
    end)

    IO.puts(String.duplicate("=", 60))
  end

  defp usage do
    """
    CertScout - cybersecurity certification demand scanner

    Usage:
      certscout [options]

    Options:
      --sources a,b,c     Sources to scrape (workday,greenhouse,lever,ashby,remoteok,usajobs,adzuna)
      --terms "x,y"       Search terms for keyword sources
      --target N | all    Cap on cybersecurity postings to analyze (default 12000)
      --top N             Number of certifications in the report (default 12)
      --concurrency N     Max concurrent requests (default 24)
      --delay MS          Max jitter delay per request in ms (default 25)
      --output DIR        Output directory (default output)
      --all               Analyze every posting, skip the cybersecurity filter
      --country CC        Country code for Adzuna (default us)
      --boards-file F     Override Greenhouse board tokens (one per line)
      --workday-file F    Override Workday sites (lines: tenant,datacenter,site)
      --lever-file F      Override Lever companies (one per line)
      --ashby-file F      Override Ashby orgs (one per line)
      --certs-file F      Override certification catalogue (JSON array)
      -h, --help          Show this help

    Optional API keys (set as environment variables):
      USAJOBS_API_KEY, USAJOBS_EMAIL    Enable the usajobs source
      ADZUNA_APP_ID, ADZUNA_APP_KEY     Enable the adzuna source
    """
  end
end
