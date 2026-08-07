defmodule Ultramoist.AssetCacheTest do
  use ExUnit.Case, async: true

  # @spec CACHE-DATA-001
  test "builds an index mapping coin name to position in the universe list" do
    universe = [%{"name" => "BTC"}, %{"name" => "ETH"}, %{"name" => "SOL"}]

    assert Ultramoist.AssetCache.build_index(universe) == %{"BTC" => 0, "ETH" => 1, "SOL" => 2}
  end

  # @spec CACHE-DATA-002
  test "resolves a known coin to its asset index" do
    index = %{"BTC" => 0, "ETH" => 1}
    assert Ultramoist.AssetCache.resolve(index, "ETH") == {:ok, 1}
  end

  # @spec CACHE-DATA-003
  test "resolves an unknown coin to a not-found result" do
    index = %{"BTC" => 0, "ETH" => 1}
    assert Ultramoist.AssetCache.resolve(index, "DOGE") == {:error, :not_found}
  end

  # @spec CACHE-API-001
  test "populates its index from the meta endpoint at startup" do
    stub = fn %{"type" => "meta"}, _opts -> {:ok, %{"universe" => [%{"name" => "BTC"}]}} end

    {:ok, pid} =
      Ultramoist.AssetCache.start_link(
        base_url: "unused",
        http: {Ultramoist.FakeHttp, stub: stub}
      )

    assert {:ok, 0} = Ultramoist.AssetCache.lookup(pid, "BTC")
  end
end
