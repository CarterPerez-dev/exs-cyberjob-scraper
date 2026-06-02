# © AngelaMos | 2026
# posting.ex

defmodule CertScout.Posting do
  @moduledoc """
  A normalized job posting, source-agnostic. Every source maps its raw payload
  into this struct so the rest of the pipeline never knows which board it came from.
  """

  @enforce_keys [:id, :source, :title]
  defstruct id: nil,
            source: nil,
            company: nil,
            title: nil,
            location: nil,
            url: nil,
            text: ""

  @type t :: %__MODULE__{
          id: String.t(),
          source: String.t(),
          company: String.t() | nil,
          title: String.t(),
          location: String.t() | nil,
          url: String.t() | nil,
          text: String.t()
        }

  @spec dedup_key(t()) :: String.t()
  def dedup_key(%__MODULE__{url: url}) when is_binary(url) and url != "", do: url
  def dedup_key(%__MODULE__{id: id}), do: id
end
