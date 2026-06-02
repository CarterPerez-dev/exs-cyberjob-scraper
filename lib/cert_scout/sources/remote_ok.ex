# © AngelaMos | 2026
# remote_ok.ex

defmodule CertScout.Sources.RemoteOK do
  @moduledoc """
  RemoteOK public API. A single keyless endpoint returns the current remote job
  feed; the first array element is a legal notice and is skipped. Small in volume,
  useful as a zero-config smoke test that the pipeline works end to end.
  """

  @behaviour CertScout.Source

  alias CertScout.Config
  alias CertScout.Html
  alias CertScout.HTTP
  alias CertScout.Log
  alias CertScout.Posting

  @impl true
  def label, do: "remoteok"

  @impl true
  def collect(%Config{} = config) do
    case HTTP.get_json("https://remoteok.com/api", config) do
      {:ok, [_legal | jobs]} when is_list(jobs) ->
        postings = Enum.map(jobs, &posting/1)
        Log.progress_done("remoteok", length(postings))
        postings

      _ ->
        Log.progress_done("remoteok", 0)
        []
    end
  end

  defp posting(job) do
    %Posting{
      id: "remoteok:#{job["id"]}",
      source: "remoteok",
      company: job["company"],
      title: job["position"] || "",
      location: job["location"],
      url: job["url"],
      text: Html.to_text(job["description"])
    }
  end
end
