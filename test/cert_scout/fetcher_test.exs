# © AngelaMos | 2026
# fetcher_test.exs

defmodule CertScout.FetcherTest do
  use ExUnit.Case, async: true

  alias CertScout.Config
  alias CertScout.Fetcher

  defp config, do: Config.new([])

  describe "collect/4" do
    test "sums scanned counts and concatenates postings" do
      result = Fetcher.collect([1, 2, 3], "t", config(), fn n -> %{scanned: n, postings: List.duplicate(:p, n)} end)

      assert result.scanned == 6
      assert length(result.postings) == 6
    end

    test "a raising worker collapses to empty and never crashes the run" do
      result =
        Fetcher.collect([:boom, :ok], "t", config(), fn
          :boom -> raise "nope"
          :ok -> %{scanned: 1, postings: [:p]}
        end)

      assert result.scanned == 1
      assert result.postings == [:p]
    end

    test "a throwing worker collapses to empty" do
      result = Fetcher.collect([:bad], "t", config(), fn _ -> throw(:oops) end)
      assert result == %{scanned: 0, postings: []}
    end

    test "a wrong-shaped worker return collapses to empty" do
      result = Fetcher.collect([:bad], "t", config(), fn _ -> :not_a_map end)
      assert result == %{scanned: 0, postings: []}
    end

    test "empty input short-circuits" do
      assert Fetcher.collect([], "t", config(), fn _ -> %{scanned: 9, postings: [:p]} end) ==
               %{scanned: 0, postings: []}
    end
  end

  describe "run/4" do
    test "concatenates the posting lists" do
      assert [1, 2] |> Fetcher.run("t", config(), fn n -> List.duplicate(:p, n) end) |> length() == 3
    end

    test "a raising worker collapses to empty" do
      result =
        Fetcher.run([:boom, :ok], "t", config(), fn
          :boom -> raise "nope"
          :ok -> [:p]
        end)

      assert result == [:p]
    end

    test "a non-list worker return collapses to empty" do
      assert Fetcher.run([:bad], "t", config(), fn _ -> %{not: :a_list} end) == []
    end

    test "empty input short-circuits" do
      assert Fetcher.run([], "t", config(), fn _ -> [:p] end) == []
    end
  end
end
