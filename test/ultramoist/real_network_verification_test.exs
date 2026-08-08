defmodule Ultramoist.RealNetworkVerificationTest do
  use ExUnit.Case, async: false

  @moduletag :real_network

  # @spec RNV-API-001
  # @spec RNV-API-002
  test "places and cancels a real limit order on Hyperliquid testnet" do
    priv_key =
      "ULTRAMOIST_TESTNET_PRIV_KEY"
      |> System.fetch_env!()
      |> String.trim_leading("0x")
      |> Base.decode16!(case: :mixed)

    base_url = Ultramoist.Config.info_url(:testnet)

    {:ok, mids} = Ultramoist.Http.info_request(%{"type" => "allMids"}, base_url: base_url)
    {btc_mid, _} = Float.parse(mids["BTC"])
    limit_price = (btc_mid * 0.5) |> trunc() |> to_string()

    {:ok, cache_pid} = Ultramoist.AssetCache.start_link(base_url: base_url)

    assert {:ok, order_id} =
             Ultramoist.Order.place_limit(cache_pid, "BTC", true, limit_price, "0.001",
               priv_key: priv_key,
               source: Ultramoist.Signer.testnet_source(),
               base_url: base_url
             )

    {:ok, %{asset_index: asset_index}} = Ultramoist.AssetCache.lookup(cache_pid, "BTC")

    assert :ok =
             Ultramoist.Order.cancel(
               asset_index: asset_index,
               order_id: order_id,
               priv_key: priv_key,
               source: Ultramoist.Signer.testnet_source(),
               base_url: base_url
             )
  end
end
