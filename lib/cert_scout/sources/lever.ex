# © AngelaMos | 2026
# lever.ex

defmodule CertScout.Sources.Lever do
  @moduledoc """
  Lever public postings. `/v0/postings/<company>?mode=json` returns every posting
  for a company including `descriptionPlain`, so no HTML parsing is needed. The
  bundled company list is verified to respond; override it with `--lever-file`.
  """

  @behaviour CertScout.Source

  alias CertScout.Config
  alias CertScout.Fetcher
  alias CertScout.Html
  alias CertScout.HTTP
  alias CertScout.Posting

  @companies ~w(plaid attentive mistral)

  @impl true
  def label, do: "lever"

  @impl true
  def collect(%Config{} = config) do
    companies = config.lever_companies || @companies
    Fetcher.run(companies, "lever", config, &fetch_company(&1, config))
  end

  defp fetch_company(company, config) do
    url = "https://api.lever.co/v0/postings/#{company}?mode=json"

    case HTTP.get_json(url, config) do
      {:ok, postings} when is_list(postings) -> Enum.map(postings, &posting(&1, company))
      _ -> []
    end
  end

  defp posting(job, company) do
    %Posting{
      id: "lever:#{company}:#{job["id"]}",
      source: "lever",
      company: company,
      title: job["text"] || "",
      location: get_in(job, ["categories", "location"]),
      url: job["hostedUrl"],
      text: description(job)
    }
  end

  defp description(job) do
    case job["descriptionPlain"] do
      text when is_binary(text) and text != "" -> text
      _ -> Html.to_text(job["description"])
    end
  end
end
