defmodule Ultramoist.AssetCacheTest do
  use ExUnit.Case, async: true

  # @spec CACHE-DATA-001
  test "builds an index mapping coin name to asset index and size decimals" do
    universe = [
      %{"name" => "BTC", "szDecimals" => 5},
      %{"name" => "ETH", "szDecimals" => 4},
      %{"name" => "SOL", "szDecimals" => 2}
    ]

    assert Ultramoist.AssetCache.build_index(universe) == %{
             "BTC" => %{asset_index: 0, size_decimals: 5},
             "ETH" => %{asset_index: 1, size_decimals: 4},
             "SOL" => %{asset_index: 2, size_decimals: 2}
           }
  end

  # @spec CACHE-DATA-002
  test "resolves a known coin to its asset index and size decimals" do
    index = %{
      "BTC" => %{asset_index: 0, size_decimals: 5},
      "ETH" => %{asset_index: 1, size_decimals: 4}
    }

    assert Ultramoist.AssetCache.resolve(index, "ETH") ==
             {:ok, %{asset_index: 1, size_decimals: 4}}
  end

  # @spec CACHE-DATA-003
  test "resolves an unknown coin to a not-found result" do
    index = %{"BTC" => %{asset_index: 0, size_decimals: 5}}
    assert Ultramoist.AssetCache.resolve(index, "DOGE") == {:error, :not_found}
  end

  # @spec CACHE-API-001
  test "populates its index from the meta endpoint at startup" do
    stub = fn %{"type" => "meta"}, _opts ->
      {:ok, %{"universe" => [%{"name" => "BTC", "szDecimals" => 5}]}}
    end

    {:ok, pid} =
      Ultramoist.AssetCache.start_link(
        base_url: "unused",
        http: {Ultramoist.FakeHttp, stub: stub}
      )

    assert {:ok, %{asset_index: 0, size_decimals: 5}} = Ultramoist.AssetCache.lookup(pid, "BTC")
  end
end
