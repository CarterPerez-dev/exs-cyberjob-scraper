# © AngelaMos | 2026
# storage_test.exs

defmodule CertScout.StorageTest do
  use ExUnit.Case, async: true

  alias CertScout.Analyzer
  alias CertScout.Certification
  alias CertScout.Posting
  alias CertScout.Storage

  test "postings.csv matched_certs come straight from the analysis, not a recompute" do
    certs = [Certification.new(slug: "cissp", name: "CISSP", issuer: "ISC2", aliases: ["CISSP"])]
    postings = [%Posting{id: "1", source: "t", title: "Security Engineer", text: "CISSP required"}]
    analysis = Analyzer.analyze(postings, certs)

    dir = Path.join(System.tmp_dir!(), "certscout_storage_#{System.unique_integer([:positive])}")

    meta = %{
      total_scraped: 1,
      cyber_postings: 1,
      companies: 0,
      sources: ["t"],
      search_terms: [],
      generated_on: Date.utc_today(),
      top_n: 5
    }

    try do
      assert Storage.write(dir, analysis, meta) == :ok
      csv = File.read!(Path.join([dir, "data", "postings.csv"]))
      assert csv =~ "cissp"
    after
      File.rm_rf!(dir)
    end
  end
end
