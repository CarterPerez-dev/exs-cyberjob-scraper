# © AngelaMos | 2026
# logos.ex

defmodule CertScout.Logos do
  @moduledoc """
  Maps each certification slug to a logo image. Real issuer marks come from
  Wikimedia Commons (hotlink-stable); issuers without a usable mark fall back to a
  generated shields.io badge. `download_all/3` localizes every logo into the
  report's `assets/` directory so the report renders with zero network access
  when it is on screen.
  """

  alias CertScout.Config

  @comptia "https://upload.wikimedia.org/wikipedia/commons/thumb/6/62/Comptia-logo.svg/250px-Comptia-logo.svg.png"
  @isc2 "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3f/ISC2_Logo.svg/250px-ISC2_Logo.svg.png"
  @isaca "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a1/ISACA_logo.png/250px-ISACA_logo.png"
  @eccouncil "https://upload.wikimedia.org/wikipedia/commons/thumb/c/cb/Ec_Council_Logo.png/250px-Ec_Council_Logo.png"
  @cisco "https://upload.wikimedia.org/wikipedia/commons/thumb/0/08/Cisco_logo_blue_2016.svg/250px-Cisco_logo_blue_2016.svg.png"
  @aws "https://upload.wikimedia.org/wikipedia/commons/thumb/9/93/Amazon_Web_Services_Logo.svg/250px-Amazon_Web_Services_Logo.svg.png"
  @microsoft "https://upload.wikimedia.org/wikipedia/commons/thumb/9/96/Microsoft_logo_%282012%29.svg/250px-Microsoft_logo_%282012%29.svg.png"

  @urls %{
    "cissp" => @isc2,
    "ccsp" => @isc2,
    "sscp" => @isc2,
    "security-plus" => @comptia,
    "cysa-plus" => @comptia,
    "casp-plus" => @comptia,
    "pentest-plus" => @comptia,
    "network-plus" => @comptia,
    "comptia-a-plus" => @comptia,
    "cism" => @isaca,
    "cisa" => @isaca,
    "crisc" => @isaca,
    "ceh" => @eccouncil,
    "ccna" => @cisco,
    "aws-security" => @aws,
    "az-500" => @microsoft,
    "oscp" => "https://img.shields.io/badge/OSCP-OffSec-557c94",
    "giac" => "https://img.shields.io/badge/GIAC-GIAC-ee2e24",
    "ccsk" => "https://img.shields.io/badge/CCSK-Cloud%20Security%20Alliance-0a66c2",
    "pmp" => "https://img.shields.io/badge/PMP-PMI-2a6db0"
  }

  @spec url(String.t()) :: String.t()
  def url(slug) do
    Map.get(@urls, slug) || "https://img.shields.io/badge/#{URI.encode(slug)}-cert-555555"
  end

  @spec extension(String.t()) :: String.t()
  def extension(slug) do
    if slug |> url() |> String.ends_with?(".svg") or String.contains?(url(slug), "shields.io") do
      "svg"
    else
      "png"
    end
  end

  @spec download_all([CertScout.Certification.t()], String.t(), Config.t()) :: :ok
  def download_all(certs, assets_dir, %Config{} = config) do
    File.mkdir_p!(assets_dir)

    Enum.each(certs, fn cert ->
      path = Path.join(assets_dir, "#{cert.slug}.#{extension(cert.slug)}")
      fetch_to(url(cert.slug), path, config)
    end)
  end

  defp fetch_to(url, path, config) do
    case Req.get(url,
           decode_body: false,
           headers: [{"user-agent", config.user_agent}],
           retry: :transient,
           retry_log_level: false
         ) do
      {:ok, %Req.Response{status: 200, body: body}} -> File.write!(path, body)
      _ -> :ok
    end
  end
end
