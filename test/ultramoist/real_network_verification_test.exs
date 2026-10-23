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

  # @spec RNV-API-004
  test "places and cancels a real limit order for a sub-account on Hyperliquid testnet" do
    priv_key =
      "ULTRAMOIST_TESTNET_PRIV_KEY"
      |> System.fetch_env!()
      |> String.trim_leading("0x")
      |> Base.decode16!(case: :mixed)

    sub_account = System.fetch_env!("ULTRAMOIST_TESTNET_SUB_ACCOUNT_ADDRESS")
    master = "0x004afA659f84A08FC6A4FD3ad3Ad3fF49C13f25F"
    base_url = Ultramoist.Config.info_url(:testnet)

    {:ok, mids} = Ultramoist.Http.info_request(%{"type" => "allMids"}, base_url: base_url)
    {btc_mid, _} = Float.parse(mids["BTC"])
    limit_price = (btc_mid * 0.5) |> trunc() |> to_string()

    {:ok, cache_pid} = Ultramoist.AssetCache.start_link(base_url: base_url)

    assert {:ok, order_id} =
             Ultramoist.Orders.Order.place_limit(cache_pid, "BTC", true, limit_price, "0.001",
               priv_key: priv_key,
               source: Ultramoist.Signer.testnet_source(),
               base_url: base_url,
               vault_address: sub_account
             )

    {:ok, sub_account_orders} = Ultramoist.Orders.fetch_open(sub_account, base_url: base_url)
    {:ok, master_orders} = Ultramoist.Orders.fetch_open(master, base_url: base_url)

    assert order_id in Enum.map(sub_account_orders, & &1.order_id)
    refute order_id in Enum.map(master_orders, & &1.order_id)

    {:ok, %{asset_index: asset_index}} = Ultramoist.AssetCache.lookup(cache_pid, "BTC")

    assert :ok =
             Ultramoist.Orders.Order.cancel(
               asset_index: asset_index,
               order_id: order_id,
               priv_key: priv_key,
               source: Ultramoist.Signer.testnet_source(),
               base_url: base_url,
               vault_address: sub_account
             )

    {:ok, sub_account_orders} = Ultramoist.Orders.fetch_open(sub_account, base_url: base_url)
    refute order_id in Enum.map(sub_account_orders, & &1.order_id)
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

  test "resolves a real HIP-3 builder-deployed asset (xyz:GOLD) alongside the native universe" do
    base_url = Ultramoist.Config.info_url(:mainnet)

    {:ok, cache_pid} =
      Ultramoist.AssetCache.start_link(base_url: base_url, dexs: [nil, "xyz"])

    assert {:ok, %{asset_index: asset_index, size_decimals: _}} =
             Ultramoist.AssetCache.lookup(cache_pid, "xyz:GOLD")

    assert asset_index >= 100_000

    assert {:ok, %{asset_index: 0}} = Ultramoist.AssetCache.lookup(cache_pid, "BTC")
  end

  test "fetches a real HIP-3 builder-deployed asset's mid price by passing its dex" do
    base_url = Ultramoist.Config.info_url(:mainnet)

    assert {:ok, price} = Ultramoist.Mids.fetch("xyz:GOLD", base_url: base_url, dex: "xyz")
    assert Decimal.gt?(price, 0)
  end

  test "fetches a real wallet's HIP-3 dex-scoped positions without erroring" do
    base_url = Ultramoist.Config.info_url(:mainnet)

    assert {:ok, positions} =
             Ultramoist.Positions.fetch("0x004afA659f84A08FC6A4FD3ad3Ad3fF49C13f25F",
               base_url: base_url,
               dex: "xyz"
             )

    assert is_list(positions)
  end

  test "fetches a real native coin's mid price, and a universe that includes it" do
    base_url = Ultramoist.Config.info_url(:mainnet)

    assert {:ok, price} = Ultramoist.Mids.fetch("BTC", base_url: base_url)
    assert Decimal.gt?(price, 0)

    assert {:ok, assets} = Ultramoist.Universe.fetch(base_url: base_url)
    assert length(assets) > 50
    assert Enum.any?(assets, &(&1.name == "BTC"))
  end

  test "fetches a real wallet's account value" do
    base_url = Ultramoist.Config.info_url(:mainnet)

    assert {:ok, %Decimal{}} =
             Ultramoist.Positions.fetch_account_value(
               "0x004afA659f84A08FC6A4FD3ad3Ad3fF49C13f25F",
               base_url: base_url
             )
  end

  test "fetches a real coin's funding rate history across more than one page, in order" do
    base_url = Ultramoist.Config.info_url(:mainnet)
    now = System.system_time(:millisecond)

    assert {:ok, rates} =
             Ultramoist.FundingRates.fetch("BTC", now - :timer.hours(24 * 30), now,
               base_url: base_url
             )

    assert length(rates) > 500
    assert Enum.all?(rates, &match?(%Ultramoist.FundingRate{coin: "BTC"}, &1))
    assert rates == Enum.sort_by(rates, & &1.time, NaiveDateTime)
  end

  test "fetches a real coin's candles in order, and none for a window before it existed" do
    base_url = Ultramoist.Config.info_url(:mainnet)
    now = System.system_time(:millisecond)

    assert {:ok, [_first | _rest] = candles} =
             Ultramoist.Candles.fetch("BTC", "1h", now - :timer.hours(24), now,
               base_url: base_url
             )

    assert candles == Enum.sort_by(candles, & &1.open_time, NaiveDateTime)
    assert {:ok, []} = Ultramoist.Candles.fetch("BTC", "1h", 0, 1000, base_url: base_url)
  end

  test "fetches a real wallet's HIP-3 dex-scoped open orders without erroring" do
    base_url = Ultramoist.Config.info_url(:mainnet)

    assert {:ok, orders} =
             Ultramoist.Orders.fetch_open("0x004afA659f84A08FC6A4FD3ad3Ad3fF49C13f25F",
               base_url: base_url,
               dex: "xyz"
             )

    assert is_list(orders)
  end
end
