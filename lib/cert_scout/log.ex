# © AngelaMos | 2026
# log.ex

defmodule CertScout.Log do
  @moduledoc """
  Progress output. Everything goes to stderr so stdout stays reserved for the
  final machine-readable summary, and the running progress line rewrites itself
  in place instead of flooding the terminal.
  """

  @spec info(iodata()) :: :ok
  def info(message), do: IO.puts(:stderr, message)

  @spec step(iodata()) :: :ok
  def step(message), do: IO.puts(:stderr, ["  -> ", message])

  @spec progress(String.t(), non_neg_integer(), non_neg_integer()) :: :ok
  def progress(label, done, total) do
    IO.write(:stderr, ["\r", pad(label), Integer.to_string(done), " / ", Integer.to_string(total), "   "])
  end

  @spec progress_done(String.t(), non_neg_integer()) :: :ok
  def progress_done(label, count) do
    IO.write(:stderr, ["\r", pad(label), Integer.to_string(count), " collected            \n"])
  end

  defp pad(label), do: String.pad_trailing(label <> ": ", 26)
end
