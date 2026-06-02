# © AngelaMos | 2026
# certification.ex

defmodule CertScout.Certification do
  @moduledoc """
  A single certification the scanner counts, with the compiled matcher used to
  detect it inside a posting's text and the logo used in the report.

  `aliases` are literal strings; they are escaped and wrapped in alphanumeric
  boundaries at compile time so `Security+` matches `Security+` but not
  `Securityplus`, and `CEH` matches `CEH` but not `CACHE`.
  """

  @enforce_keys [:slug, :name, :aliases]
  defstruct slug: nil, name: nil, issuer: nil, aliases: [], logo: nil, regex: nil

  @type t :: %__MODULE__{
          slug: String.t(),
          name: String.t(),
          issuer: String.t() | nil,
          aliases: [String.t()],
          logo: String.t() | nil,
          regex: Regex.t() | nil
        }

  @spec new(keyword()) :: t()
  def new(fields) do
    cert = struct!(__MODULE__, fields)
    %{cert | regex: compile(cert.aliases)}
  end

  @spec mentioned?(t(), String.t()) :: boolean()
  def mentioned?(%__MODULE__{regex: regex}, text) when is_binary(text) do
    Regex.match?(regex, text)
  end

  defp compile(aliases) do
    body = Enum.map_join(aliases, "|", &Regex.escape/1)

    Regex.compile!("(?<![A-Za-z0-9])(?:#{body})(?![A-Za-z0-9+])", "i")
  end
end
