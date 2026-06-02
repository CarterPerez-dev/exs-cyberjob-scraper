# © AngelaMos | 2026
# analyzer.ex

defmodule CertScout.Analyzer do
  @moduledoc """
  Counts, ranks, and computes the share of postings mentioning each
  certification. A posting is counted at most once per certification regardless
  of how many times it names it. Matching runs across schedulers because it is
  embarrassingly parallel; the result is order-independent, so the function stays
  pure and deterministic.

  Matching is the expensive part and it is done exactly once: `analyze/2` returns
  the per-posting matches alongside the ranking, so downstream stages (storage)
  read the result instead of recomputing it.
  """

  alias CertScout.Certification
  alias CertScout.Posting

  @type matched :: %{posting: Posting.t(), slugs: [String.t()]}
  @type result :: %{cert: Certification.t(), count: non_neg_integer(), percent: float()}
  @type analysis :: %{total: non_neg_integer(), results: [result()], matched: [matched()]}

  @spec analyze([Posting.t()], [Certification.t()]) :: analysis()
  def analyze(postings, certs) do
    total = length(postings)

    matched =
      postings
      |> Task.async_stream(fn posting -> %{posting: posting, slugs: matched_slugs(posting.text, certs)} end,
        max_concurrency: System.schedulers_online(),
        ordered: false,
        timeout: :infinity
      )
      |> Enum.flat_map(fn
        {:ok, entry} -> [entry]
        _ -> []
      end)

    counts =
      Enum.reduce(matched, zero_counts(certs), fn %{slugs: slugs}, acc ->
        Enum.reduce(slugs, acc, &Map.update!(&2, &1, fn n -> n + 1 end))
      end)

    results =
      certs
      |> Enum.map(fn cert ->
        count = Map.fetch!(counts, cert.slug)
        %{cert: cert, count: count, percent: percent(count, total)}
      end)
      |> Enum.sort_by(&{-&1.count, &1.cert.name})

    %{total: total, results: results, matched: matched}
  end

  defp matched_slugs(text, certs) do
    for cert <- certs, Certification.mentioned?(cert, text), do: cert.slug
  end

  defp zero_counts(certs), do: Map.new(certs, &{&1.slug, 0})

  defp percent(_count, 0), do: 0.0
  defp percent(count, total), do: Float.round(count / total * 100, 1)
end
