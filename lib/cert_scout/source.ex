# © AngelaMos | 2026
# source.ex

defmodule CertScout.Source do
  @moduledoc """
  Behaviour every data source implements, plus the registry that maps a source
  key (`:workday`, `:greenhouse`, ...) to its module. A source receives the
  config and returns a list of normalized postings; how it paginates, throttles,
  and parses is entirely its own business.
  """

  alias CertScout.Config
  alias CertScout.Posting

  @callback label() :: String.t()
  @callback collect(Config.t()) :: [Posting.t()]

  @registry %{
    workday: CertScout.Sources.Workday,
    greenhouse: CertScout.Sources.Greenhouse,
    lever: CertScout.Sources.Lever,
    ashby: CertScout.Sources.Ashby,
    remoteok: CertScout.Sources.RemoteOK,
    usajobs: CertScout.Sources.USAJobs,
    adzuna: CertScout.Sources.Adzuna
  }

  @spec module(atom()) :: module() | nil
  def module(key), do: Map.get(@registry, key)

  @spec keys() :: [atom()]
  def keys, do: Map.keys(@registry)
end
