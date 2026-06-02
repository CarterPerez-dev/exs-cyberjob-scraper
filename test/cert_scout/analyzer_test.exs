# © AngelaMos | 2026
# analyzer_test.exs

defmodule CertScout.AnalyzerTest do
  use ExUnit.Case, async: true

  alias CertScout.Analyzer
  alias CertScout.Certification
  alias CertScout.Posting

  defp posting(text), do: %Posting{id: text, source: "test", title: "Security Engineer", text: text}

  defp certs do
    [
      Certification.new(slug: "cissp", name: "CISSP", issuer: "ISC2", aliases: ["CISSP"]),
      Certification.new(slug: "secplus", name: "Security+", issuer: "CompTIA", aliases: ["Security+"])
    ]
  end

  test "counts each certification once per posting and ranks by demand" do
    postings = [
      posting("Must hold CISSP and Security+. CISSP CISSP CISSP."),
      posting("CISSP preferred"),
      posting("No certifications mentioned here")
    ]

    %{total: total, results: results} = Analyzer.analyze(postings, certs())

    assert total == 3
    [first, second] = results

    assert first.cert.slug == "cissp"
    assert first.count == 2
    assert first.percent == 66.7

    assert second.cert.slug == "secplus"
    assert second.count == 1
    assert second.percent == 33.3
  end

  test "empty posting set yields zero counts and zero percent" do
    %{total: 0, results: results} = Analyzer.analyze([], certs())
    assert Enum.all?(results, &(&1.count == 0 and &1.percent == 0.0))
  end
end
