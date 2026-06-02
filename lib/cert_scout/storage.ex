# © AngelaMos | 2026
# storage.ex

defmodule CertScout.Storage do
  @moduledoc """
  Writes the raw artifacts to `<output>/data`: the analyzed postings (JSON + CSV),
  the certification tally (JSON + CSV), and a run summary. JSON is encoded with the
  built-in `JSON` module; CSV with NimbleCSV.
  """

  alias CertScout.Certification
  alias CertScout.CSV
  alias CertScout.Posting

  NimbleCSV.define(CSV, separator: ",", escape: "\"")

  @spec write(String.t(), [Posting.t()], map(), [Certification.t()], map()) :: :ok
  def write(output_dir, postings, analysis, certs, meta) do
    data_dir = Path.join(output_dir, "data")
    File.mkdir_p!(data_dir)

    write_postings(data_dir, postings, certs)
    write_certifications(data_dir, analysis)
    write_summary(data_dir, analysis, meta)
    :ok
  end

  defp write_postings(dir, postings, certs) do
    rows = Enum.map(postings, &posting_map(&1, certs))

    File.write!(Path.join(dir, "postings.json"), JSON.encode!(rows))

    csv =
      [["id", "source", "company", "title", "location", "url", "matched_certs"]]
      |> Stream.concat(
        Enum.map(rows, fn r ->
          [r.id, r.source, r.company || "", r.title, r.location || "", r.url || "", Enum.join(r.matched_certs, ";")]
        end)
      )
      |> CSV.dump_to_iodata()

    File.write!(Path.join(dir, "postings.csv"), csv)
  end

  defp write_certifications(dir, %{total: total, results: results}) do
    ranked =
      results
      |> Enum.with_index(1)
      |> Enum.map(fn {r, rank} ->
        %{
          rank: rank,
          slug: r.cert.slug,
          name: r.cert.name,
          issuer: r.cert.issuer,
          postings: r.count,
          percent: r.percent
        }
      end)

    File.write!(Path.join(dir, "certifications.json"), JSON.encode!(%{total_cyber_postings: total, ranking: ranked}))

    csv =
      [["rank", "certification", "issuer", "postings", "percent_of_cyber_postings"]]
      |> Stream.concat(
        Enum.map(ranked, fn r ->
          [r.rank, r.name, r.issuer || "", r.postings, r.percent]
        end)
      )
      |> CSV.dump_to_iodata()

    File.write!(Path.join(dir, "certifications.csv"), csv)
  end

  defp write_summary(dir, %{total: total, results: results}, meta) do
    summary =
      meta
      |> Map.put(:cyber_postings, total)
      |> Map.put(
        :top,
        Enum.map(Enum.take(results, meta.top_n), &%{name: &1.cert.name, postings: &1.count, percent: &1.percent})
      )

    File.write!(Path.join(dir, "summary.json"), JSON.encode!(summary))
  end

  defp posting_map(%Posting{} = p, certs) do
    %{
      id: p.id,
      source: p.source,
      company: p.company,
      title: p.title,
      location: p.location,
      url: p.url,
      matched_certs: for(c <- certs, Certification.mentioned?(c, p.text), do: c.slug)
    }
  end
end
