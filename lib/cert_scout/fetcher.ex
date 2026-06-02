# © AngelaMos | 2026
# fetcher.ex

defmodule CertScout.Fetcher do
  @moduledoc """
  Bounded-concurrency fan-out. Maps a worker over a list of work items with
  `Task.async_stream`, capped at `max_concurrency` for back-pressure, killing any
  task that exceeds the timeout so a single hung host cannot stall the run. The
  worker returns a list of postings; failures collapse to an empty list and are
  counted, never raised. Progress is reported live as postings accumulate.
  """

  alias CertScout.Config
  alias CertScout.Log

  @spec run([term()], String.t(), Config.t(), (term() -> [term()])) :: [term()]
  def run([], _label, _config, _worker), do: []

  def run(items, label, %Config{} = config, worker) do
    total = length(items)
    counter = :counters.new(2, [])

    results =
      items
      |> Task.async_stream(
        fn item -> safe(worker, item) end,
        max_concurrency: config.max_concurrency,
        timeout: config.timeout_ms + 15_000,
        on_timeout: :kill_task,
        ordered: false
      )
      |> Enum.flat_map(fn outcome ->
        postings = unwrap(outcome)
        :counters.add(counter, 1, 1)
        :counters.add(counter, 2, length(postings))
        Log.progress(label, :counters.get(counter, 1), total)
        postings
      end)

    Log.progress_done(label, :counters.get(counter, 2))
    results
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

  defp unwrap({:ok, postings}) when is_list(postings), do: postings
  defp unwrap(_), do: []
end
