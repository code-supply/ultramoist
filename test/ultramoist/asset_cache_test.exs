defmodule Ultramoist.AssetCacheTest do
  use ExUnit.Case, async: false

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
  test "populates its index from the real testnet meta endpoint at startup" do
    Application.put_env(:ultramoist, :chain, :testnet)
    on_exit(fn -> Application.delete_env(:ultramoist, :chain) end)

    {:ok, pid} = Ultramoist.AssetCache.start_link([])

    assert {:ok, _asset_index} = Ultramoist.AssetCache.lookup(pid, "BTC")
  end
end
