defmodule Ultramoist.ConfigTest do
  use ExUnit.Case, async: false

  setup do
    on_exit(fn -> Application.delete_env(:ultramoist, :chain) end)
  end

  # @spec CFG-DATA-002
  test "resolves different info URLs for mainnet vs testnet" do
    Application.put_env(:ultramoist, :chain, :mainnet)
    assert Ultramoist.Config.info_url() == "https://api.hyperliquid.xyz"

    Application.put_env(:ultramoist, :chain, :testnet)
    assert Ultramoist.Config.info_url() == "https://api.hyperliquid-testnet.xyz"
  end

  # @spec CFG-DATA-001
  test "resolves the stats URL on a separate host from the info URL" do
    Application.put_env(:ultramoist, :chain, :testnet)
    assert Ultramoist.Config.stats_url() == "https://stats-data.hyperliquid.xyz/Testnet"
  end

  # @spec CFG-DATA-003
  test "raises when chain is not configured" do
    Application.delete_env(:ultramoist, :chain)
    assert_raise ArgumentError, fn -> Ultramoist.Config.info_url() end
  end

  test "resolves the info URL for an explicit chain, without touching global config" do
    assert Ultramoist.Config.info_url(:testnet) == "https://api.hyperliquid-testnet.xyz"
    assert Ultramoist.Config.info_url(:mainnet) == "https://api.hyperliquid.xyz"
  end

  test "resolves the stats URL for an explicit chain, without touching global config" do
    assert Ultramoist.Config.stats_url(:testnet) == "https://stats-data.hyperliquid.xyz/Testnet"
    assert Ultramoist.Config.stats_url(:mainnet) == "https://stats-data.hyperliquid.xyz/Mainnet"
  end
end
