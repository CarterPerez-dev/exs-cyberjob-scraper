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
  alias CertScout.Cyber
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
        postings =
          jobs
          |> Enum.filter(&keep?(&1["position"], config))
          |> Enum.map(&posting/1)

        Log.progress_done("remoteok", length(postings))
        %{scanned: length(jobs), postings: postings}

      _ ->
        Log.progress_done("remoteok", 0)
        %{scanned: 0, postings: []}
    end
  end

  defp keep?(title, %Config{include_all: true}) when is_binary(title), do: title != ""
  defp keep?(title, _config) when is_binary(title), do: Cyber.match?(title)
  defp keep?(_title, _config), do: false

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
