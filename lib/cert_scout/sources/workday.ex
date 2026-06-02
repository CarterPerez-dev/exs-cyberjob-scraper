# © AngelaMos | 2026
# workday.ex

defmodule CertScout.Sources.Workday do
  @moduledoc """
  Workday CXS boards, the engine behind the volume. Enterprise and defense
  employers host hundreds of cybersecurity roles each and mandate certifications
  (DoD 8570/8140), so their descriptions are cert-rich. Each site is searched by
  keyword with offset pagination to gather job references, then full descriptions
  are fetched concurrently. Override the site list with `--workday-file` (lines of
  `tenant,datacenter,site`).
  """

  @behaviour CertScout.Source

  alias CertScout.Config
  alias CertScout.Cyber
  alias CertScout.Fetcher
  alias CertScout.Html
  alias CertScout.HTTP
  alias CertScout.Posting

  @page_size 20
  @max_pages_per_term 25

  @sites [
    %{tenant: "bah", dc: "wd1", site: "BAH_Jobs"},
    %{tenant: "leidos", dc: "wd5", site: "External"},
    %{tenant: "caci", dc: "wd1", site: "External"},
    %{tenant: "nvidia", dc: "wd5", site: "NVIDIAExternalCareerSite"},
    %{tenant: "mastercard", dc: "wd1", site: "CorporateCareers"},
    %{tenant: "pwc", dc: "wd3", site: "Global_Experienced_Careers"},
    %{tenant: "cvshealth", dc: "wd1", site: "CVS_Health_Careers"},
    %{tenant: "salesforce", dc: "wd12", site: "External_Career_Site"},
    %{tenant: "paypal", dc: "wd1", site: "jobs"},
    %{tenant: "adobe", dc: "wd5", site: "external_experienced"},
    %{tenant: "workday", dc: "wd5", site: "Workday"},
    %{tenant: "comcast", dc: "wd5", site: "Comcast_Careers"},
    %{tenant: "humana", dc: "wd5", site: "Humana_External_Career_Site"},
    %{tenant: "tmobile", dc: "wd1", site: "External"},
    %{tenant: "pnc", dc: "wd5", site: "External"},
    %{tenant: "travelers", dc: "wd5", site: "External"},
    %{tenant: "autodesk", dc: "wd1", site: "Ext"},
    %{tenant: "bmo", dc: "wd3", site: "External"}
  ]

  @impl true
  def label, do: "workday"

  @impl true
  def collect(%Config{} = config) do
    sites = config.workday_sites || @sites

    for_result = for(site <- sites, term <- config.search_terms, do: {site, term})

    scanned =
      for_result
      |> Fetcher.run("workday search", config, &search(&1, config))
      |> Enum.uniq_by(& &1.url)

    refs =
      scanned
      |> Enum.filter(&Cyber.keep?(&1.title, config))
      |> Enum.take(config.per_source_cap)

    postings = Fetcher.run(refs, "workday detail", config, &detail(&1, config))
    %{scanned: length(scanned), postings: postings}
  end

  defp search({site, term}, config) do
    base = base_url(site)

    Enum.reduce_while(0..(@max_pages_per_term - 1), [], fn page, acc ->
      offset = page * @page_size
      body = %{appliedFacets: %{}, limit: @page_size, offset: offset, searchText: term}

      case HTTP.post_json(base <> "/jobs", body, config) do
        {:ok, %{"jobPostings" => postings}} when is_list(postings) and postings != [] ->
          refs = acc ++ Enum.map(postings, &ref(&1, site, base))
          if length(postings) < @page_size, do: {:halt, refs}, else: {:cont, refs}

        _ ->
          {:halt, acc}
      end
    end)
  end

  defp ref(posting, site, base) do
    path = posting["externalPath"]

    %{
      site: site,
      company: site.tenant,
      path: path,
      title: posting["title"] || "",
      location: posting["locationsText"],
      url: base <> path
    }
  end

  defp detail(ref, config) do
    detail_url = base_url(ref.site) <> ref.path

    case HTTP.get_json(detail_url, config) do
      {:ok, %{"jobPostingInfo" => info}} when is_map(info) -> [posting(ref, info)]
      _ -> [fallback(ref)]
    end
  end

  defp posting(ref, info) do
    %Posting{
      id: "workday:#{ref.site.tenant}:#{ref.path}",
      source: "workday",
      company: ref.company,
      title: info["title"] || ref.title,
      location: info["location"] || ref.location,
      url: info["externalUrl"] || ref.url,
      text: Html.to_text(info["jobDescription"])
    }
  end

  defp fallback(ref) do
    %Posting{
      id: "workday:#{ref.site.tenant}:#{ref.path}",
      source: "workday",
      company: ref.company,
      title: ref.title,
      location: ref.location,
      url: ref.url,
      text: ref.title
    }
  end

  defp base_url(%{tenant: tenant, dc: dc, site: site}) do
    "https://#{tenant}.#{dc}.myworkdayjobs.com/wday/cxs/#{tenant}/#{site}"
  end
end
