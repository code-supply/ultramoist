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
             Ultramoist.Orders.Order.place_limit(cache_pid, "BTC", true, limit_price, "0.001",
               priv_key: priv_key,
               source: Ultramoist.Signer.testnet_source(),
               base_url: base_url
             )

    {:ok, %{asset_index: asset_index}} = Ultramoist.AssetCache.lookup(cache_pid, "BTC")

    assert :ok =
             Ultramoist.Orders.Order.cancel(
               asset_index: asset_index,
               order_id: order_id,
               priv_key: priv_key,
               source: Ultramoist.Signer.testnet_source(),
               base_url: base_url
             )
  end

  # @spec RNV-API-003
  test "places and cancels a batch of real limit orders on Hyperliquid testnet" do
    priv_key =
      "ULTRAMOIST_TESTNET_PRIV_KEY"
      |> System.fetch_env!()
      |> String.trim_leading("0x")
      |> Base.decode16!(case: :mixed)

    base_url = Ultramoist.Config.info_url(:testnet)

    {:ok, mids} = Ultramoist.Http.info_request(%{"type" => "allMids"}, base_url: base_url)
    {btc_mid, _} = Float.parse(mids["BTC"])
    limit_price_1 = (btc_mid * 0.5) |> trunc() |> to_string()
    limit_price_1 = limit_price_1 <> ".00"
    limit_price_2 = (btc_mid * 0.4) |> trunc() |> to_string()
    limit_price_2 = limit_price_2 <> ".000"

    {:ok, cache_pid} = Ultramoist.AssetCache.start_link(base_url: base_url)

    orders = [
      {"BTC", true, limit_price_1, "0.0010"},
      {"BTC", true, limit_price_2, "0.001000"}
    ]

    assert [{:ok, order_id_1}, {:ok, order_id_2}] =
             Ultramoist.Orders.Order.place_limit_batch(cache_pid, orders,
               priv_key: priv_key,
               source: Ultramoist.Signer.testnet_source(),
               base_url: base_url
             )

    {:ok, %{asset_index: asset_index}} = Ultramoist.AssetCache.lookup(cache_pid, "BTC")

    assert [:ok, :ok] =
             Ultramoist.Orders.Order.cancel_batch(
               [{asset_index, order_id_1}, {asset_index, order_id_2}],
               priv_key: priv_key,
               source: Ultramoist.Signer.testnet_source(),
               base_url: base_url
             )
  end

  # A known-active Hyperliquid Vault (HLP Strategy A) that reliably has
  # position changes to report - used only to confirm the real API's
  # clearinghouseState message still matches the shape consumers parse.
  @active_vault_address "0xc64cc00b46101bd40aa1c3121195e85c0b0918d8"

  test "a live clearinghouseState subscription delivers a real vault's equity update" do
    {:ok, pid} =
      Ultramoist.WebSocket.start_link(
        url: Ultramoist.Config.web_socket_url(:testnet),
        transport: Ultramoist.WebSocket.MintTransport
      )

    test_pid = self()

    :ok =
      Ultramoist.WebSocket.subscribe(
        pid,
        :vault_equity,
        %{"type" => "clearinghouseState", "user" => @active_vault_address, "dex" => ""},
        fn message -> send(test_pid, {:message, message}) end
      )

    assert_receive {:message,
                     %{
                       "channel" => "clearinghouseState",
                       "data" => %{
                         "clearinghouseState" => %{
                           "marginSummary" => %{"accountValue" => _},
                           "time" => _
                         }
                       }
                     }},
                    20_000
  end
end
