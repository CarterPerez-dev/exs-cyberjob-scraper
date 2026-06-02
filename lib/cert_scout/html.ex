# © AngelaMos | 2026
# html.ex

defmodule CertScout.Html do
  @moduledoc """
  Turns the HTML (often entity-escaped) that boards return into clean plain text
  suitable for keyword scanning. Greenhouse double-encodes its `content` field,
  so entities are unescaped before parsing.
  """

  @entities %{
    "amp" => "&",
    "lt" => "<",
    "gt" => ">",
    "quot" => "\"",
    "apos" => "'",
    "nbsp" => " ",
    "mdash" => "-",
    "ndash" => "-",
    "rsquo" => "'",
    "lsquo" => "'",
    "ldquo" => "\"",
    "rdquo" => "\"",
    "hellip" => "..."
  }

  @spec to_text(binary() | nil) :: String.t()
  def to_text(nil), do: ""
  def to_text(""), do: ""

  def to_text(html) when is_binary(html) do
    html
    |> unescape()
    |> parse()
    |> collapse()
  end

  @spec unescape(String.t()) :: String.t()
  def unescape(string) do
    string
    |> replace_numeric_entities()
    |> replace_named_entities()
  end

  defp parse(html) do
    case Floki.parse_fragment(html) do
      {:ok, nodes} -> Floki.text(nodes, sep: " ")
      _ -> Regex.replace(~r/<[^>]+>/, html, " ")
    end
  end

  defp collapse(text) do
    text
    |> String.replace(~r/\s+/u, " ")
    |> String.trim()
  end

  defp replace_numeric_entities(string) do
    Regex.replace(~r/&#(x?)([0-9a-fA-F]+);/, string, fn _, hex, code ->
      base = if hex == "", do: 10, else: 16

      case Integer.parse(code, base) do
        {n, _} -> safe_codepoint(n)
        :error -> ""
      end
    end)
  end

  defp safe_codepoint(n) when n in 0..0xD7FF or n in 0xE000..0x10FFFF, do: <<n::utf8>>
  defp safe_codepoint(_), do: ""

  defp replace_named_entities(string) do
    Regex.replace(~r/&([a-zA-Z]+);/, string, fn whole, name ->
      Map.get(@entities, name, whole)
    end)
  end
end
