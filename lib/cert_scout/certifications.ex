# © AngelaMos | 2026
# certifications.ex

defmodule CertScout.Certifications do
  @moduledoc """
  The default catalogue of certifications the scanner looks for. Override it with
  `--certs-file path.json` where the file is a JSON array of objects with
  `slug`, `name`, `issuer`, `aliases` and optional `logo`.
  """

  alias CertScout.Certification

  @catalogue [
    [slug: "cissp", name: "CISSP", issuer: "ISC2", aliases: ["CISSP"]],
    [
      slug: "security-plus",
      name: "CompTIA Security+",
      issuer: "CompTIA",
      aliases: ["Security+", "CompTIA Security+", "Sec+"]
    ],
    [slug: "cism", name: "CISM", issuer: "ISACA", aliases: ["CISM"]],
    [slug: "cisa", name: "CISA", issuer: "ISACA", aliases: ["CISA"]],
    [
      slug: "ceh",
      name: "CEH",
      issuer: "EC-Council",
      aliases: ["CEH", "Certified Ethical Hacker"]
    ],
    [
      slug: "oscp",
      name: "OSCP",
      issuer: "OffSec",
      aliases: ["OSCP", "Offensive Security Certified Professional"]
    ],
    [slug: "cysa-plus", name: "CompTIA CySA+", issuer: "CompTIA", aliases: ["CySA+", "CySA"]],
    [slug: "ccsp", name: "CCSP", issuer: "ISC2", aliases: ["CCSP"]],
    [slug: "gsec", name: "GIAC GSEC", issuer: "GIAC", aliases: ["GSEC"]],
    [slug: "gcih", name: "GIAC GCIH", issuer: "GIAC", aliases: ["GCIH"]],
    [slug: "gpen", name: "GIAC GPEN", issuer: "GIAC", aliases: ["GPEN"]],
    [slug: "gcia", name: "GIAC GCIA", issuer: "GIAC", aliases: ["GCIA"]],
    [slug: "grem", name: "GIAC GREM", issuer: "GIAC", aliases: ["GREM"]],
    [
      slug: "giac",
      name: "GIAC (other)",
      issuer: "GIAC",
      aliases: ["GIAC", "GCFA", "GWAPT", "GMON", "GCFE", "GCFR", "GDSA", "GXPN"]
    ],
    [slug: "casp-plus", name: "CompTIA CASP+ / SecurityX", issuer: "CompTIA", aliases: ["CASP+", "CASP", "SecurityX"]],
    [slug: "pentest-plus", name: "CompTIA PenTest+", issuer: "CompTIA", aliases: ["PenTest+"]],
    [slug: "network-plus", name: "CompTIA Network+", issuer: "CompTIA", aliases: ["Network+"]],
    [slug: "crisc", name: "CRISC", issuer: "ISACA", aliases: ["CRISC"]],
    [slug: "sscp", name: "SSCP", issuer: "ISC2", aliases: ["SSCP"]],
    [slug: "ccsk", name: "CCSK", issuer: "Cloud Security Alliance", aliases: ["CCSK"]],
    [slug: "ccna", name: "CCNA", issuer: "Cisco", aliases: ["CCNA"]],
    [
      slug: "aws-security",
      name: "AWS Certified Security",
      issuer: "AWS",
      aliases: ["AWS Certified Security", "AWS Security Specialty"]
    ],
    [
      slug: "az-500",
      name: "Azure Security Engineer (AZ-500)",
      issuer: "Microsoft",
      aliases: ["AZ-500", "Azure Security Engineer"]
    ],
    [slug: "comptia-a-plus", name: "CompTIA A+", issuer: "CompTIA", aliases: ["CompTIA A+"]],
    [
      slug: "sc-200",
      name: "Microsoft SC-200 (Security Operations Analyst)",
      issuer: "Microsoft",
      aliases: ["SC-200", "Security Operations Analyst Associate"]
    ],
    [
      slug: "sc-300",
      name: "Microsoft SC-300 (Identity & Access Administrator)",
      issuer: "Microsoft",
      aliases: ["SC-300", "Identity and Access Administrator Associate"]
    ],
    [
      slug: "sc-100",
      name: "Microsoft SC-100 (Cybersecurity Architect)",
      issuer: "Microsoft",
      aliases: ["SC-100", "Cybersecurity Architect Expert"]
    ],
    [
      slug: "gcp-security",
      name: "Google Professional Cloud Security Engineer",
      issuer: "Google",
      aliases: ["Professional Cloud Security Engineer", "GCP Security Engineer"]
    ],
    [slug: "pcnse", name: "Palo Alto PCNSE", issuer: "Palo Alto Networks", aliases: ["PCNSE"]],
    [
      slug: "fortinet-nse",
      name: "Fortinet NSE / FCSS",
      issuer: "Fortinet",
      aliases: ["Fortinet NSE", "FCSS", "FCP", "NSE 4", "NSE 7", "NSE 8"]
    ],
    [
      slug: "splunk",
      name: "Splunk Certified",
      issuer: "Splunk",
      aliases: ["Splunk Certified", "Splunk Core Certified", "Splunk Enterprise Security Certified"]
    ],
    [
      slug: "cbrops",
      name: "Cisco CyberOps Associate",
      issuer: "Cisco",
      aliases: ["CyberOps", "CBROPS", "Cisco CyberOps"]
    ],
    [slug: "osep", name: "OSEP", issuer: "OffSec", aliases: ["OSEP"]],
    [slug: "oswe", name: "OSWE", issuer: "OffSec", aliases: ["OSWE"]],
    [slug: "pmp", name: "PMP", issuer: "PMI", aliases: ["PMP"]]
  ]

  @spec default() :: [Certification.t()]
  def default, do: Enum.map(@catalogue, &Certification.new/1)

  @spec from_json(String.t()) :: [Certification.t()]
  def from_json(raw) do
    raw
    |> JSON.decode!()
    |> Enum.map(fn entry ->
      Certification.new(
        slug: entry["slug"],
        name: entry["name"],
        issuer: entry["issuer"],
        aliases: entry["aliases"],
        logo: entry["logo"]
      )
    end)
  end
end
