# © AngelaMos | 2026
# cyber.ex

defmodule CertScout.Cyber do
  @moduledoc """
  Decides whether a posting title is a genuine cybersecurity role. Sources that
  do not pre-filter (Greenhouse, Lever) return every job they hold; this is the
  precision gate that isolates the cybersecurity subset for the cert analysis.

  Positive signals are role keywords; negative signals strip physical-security
  and content-moderation roles that share the word "security".
  """

  @positive ~r/\b(?:cyber|cybersecurity|infosec|information security|security engineer|security analyst|security architect|security operations|appsec|application security|product security|cloud security|network security|offensive security|penetration test|pentest|red team|blue team|purple team|threat (?:intel|hunt|detection)|incident response|vulnerability|malware|forensic|detection engineer|soc analyst|security operations center|grc|identity and access|\biam\b|\bsiem\b|devsecops|ciso|cryptograph)/i

  @negative ~r/\b(?:security (?:officer|guard|supervisor|attendant|patrol)|physical security|loss prevention|guard|trust (?:and|&) safety)\b/i

  @spec match?(String.t()) :: boolean()
  def match?(title) when is_binary(title) do
    Regex.match?(@positive, title) and not Regex.match?(@negative, title)
  end

  def match?(_), do: false
end
