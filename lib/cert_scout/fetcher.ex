# © AngelaMos | 2026
# fetcher.ex

defmodule CertScout.Fetcher do
  @moduledoc """
  Bounded-concurrency fan-out. Maps a worker over a list of work items with
  `Task.async_stream`, capped at `max_concurrency` for back-pressure, killing any
  task that exceeds the timeout so a single hung host cannot stall the run. The
  worker returns a list of postings; failures collapse to an empty list and are
  counted, never raised. Progress is reported live as results accumulate.

  Two entry points share one engine: `collect/4` is for workers that also report
  how many raw items they scanned (the `%{scanned, postings}` contract), `run/4`
  is for workers that only return a posting list and let the caller tally what
  "scanned" means. The stream is consumed by a single process, so a plain reduce
  accumulator is the right tool — no atomics needed.
  """

  alias CertScout.Config
  alias CertScout.Log

  @spec collect([term()], String.t(), Config.t(), (term() -> %{scanned: non_neg_integer(), postings: [term()]})) ::
          %{scanned: non_neg_integer(), postings: [term()]}
  def collect([], _label, _config, _worker), do: %{scanned: 0, postings: []}

  def collect(items, label, %Config{} = config, worker) do
    stream(items, label, config, fn item -> safe_map(worker, item) end)
  end

  @spec run([term()], String.t(), Config.t(), (term() -> [term()])) :: [term()]
  def run([], _label, _config, _worker), do: []

  def run(items, label, %Config{} = config, worker) do
    %{postings: postings} = stream(items, label, config, fn item -> %{scanned: 0, postings: safe(worker, item)} end)
    postings
  end

  defp stream(items, label, %Config{} = config, worker) do
    total = length(items)

    {_done, scanned, chunks} =
      items
      |> Task.async_stream(worker,
        max_concurrency: config.max_concurrency,
        timeout: config.timeout_ms + 15_000,
        on_timeout: :kill_task,
        ordered: false
      )
      |> Enum.reduce({0, 0, []}, fn outcome, {done, scanned, chunks} ->
        %{scanned: s, postings: p} = unwrap(outcome)
        done = done + 1
        Log.progress(label, done, total)
        {done, scanned + s, [p | chunks]}
      end)

    postings = chunks |> Enum.reverse() |> Enum.concat()
    Log.progress_done(label, length(postings))
    %{scanned: scanned, postings: postings}
  end

  defp safe(worker, item) do
    case worker.(item) do
      list when is_list(list) -> list
      _ -> []
    end
  rescue
    _ -> []
  catch
    _, _ -> []
  end

  defp safe_map(worker, item) do
    case worker.(item) do
      %{scanned: _, postings: _} = result -> result
      _ -> %{scanned: 0, postings: []}
    end
  rescue
    _ -> %{scanned: 0, postings: []}
  catch
    _, _ -> %{scanned: 0, postings: []}
  end

  defp unwrap({:ok, %{scanned: _, postings: _} = result}), do: result
  defp unwrap(_), do: %{scanned: 0, postings: []}
end
