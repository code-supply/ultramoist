defmodule Ultramoist.Orders.OrderTest do
  use ExUnit.Case, async: true

  # @spec ORD-DATA-001
  test "builds a GTC limit-order action from an asset index, side, price, and size" do
    assert Ultramoist.Orders.Order.build_place_action(0, true, "100.5", "0.1") == [
             type: "order",
             orders: [
               [a: 0, b: true, p: "100.5", s: "0.1", r: false, t: [limit: [tif: "Gtc"]]]
             ],
             grouping: "na"
           ]
  end

  # @spec ORD-DATA-002
  test "parses a successful order-placement response into the resulting order id" do
    response = %{
      "status" => "ok",
      "response" => %{
        "type" => "order",
        "data" => %{"statuses" => [%{"resting" => %{"oid" => 12345}}]}
      }
    }

    assert Ultramoist.Orders.Order.parse_place_response(response) == {:ok, 12345}
  end

  # @spec ORD-DATA-003
  test "parses a rejected order-placement response into the exchange's rejection reason" do
    response = %{
      "status" => "ok",
      "response" => %{
        "type" => "order",
        "data" => %{"statuses" => [%{"error" => "Price must be divisible by tick size."}]}
      }
    }

    assert Ultramoist.Orders.Order.parse_place_response(response) ==
             {:error, "Price must be divisible by tick size."}
  end

  # @spec ORD-DATA-006
  test "parses an order-placement response that filled immediately into the resulting order id" do
    response = %{
      "status" => "ok",
      "response" => %{
        "type" => "order",
        "data" => %{
          "statuses" => [%{"filled" => %{"totalSz" => "0.1", "avgPx" => "100.5", "oid" => 12345}}]
        }
      }
    }

    assert Ultramoist.Orders.Order.parse_place_response(response) == {:ok, 12345}
  end

  # @spec LEV-DATA-001
  test "builds an updateLeverage action from an asset index, cross-margin flag, and leverage value" do
    assert Ultramoist.Orders.Order.build_update_leverage_action(
             asset_index: 0,
             is_cross: true,
             leverage: 5
           ) == [
             type: "updateLeverage",
             asset: 0,
             isCross: true,
             leverage: 5
           ]
  end

  # @spec LEV-DATA-001
  test "parses a successful updateLeverage response into confirmation" do
    response = %{
      "status" => "ok",
      "response" => %{"type" => "default", "data" => %{}}
    }

    assert Ultramoist.Orders.Order.parse_update_leverage_response(response) == :ok
  end

  # @spec LEV-DATA-001
  test "parses a rejected updateLeverage response into the exchange's rejection reason" do
    response = %{"status" => "err", "response" => "Invalid leverage value"}

    assert Ultramoist.Orders.Order.parse_update_leverage_response(response) ==
             {:error, "Invalid leverage value"}
  end

  # @spec ORD-DATA-004
  test "builds a cancel action from an asset index and order id" do
    assert Ultramoist.Orders.Order.build_cancel_action(0, 12345) == [
             type: "cancel",
             cancels: [[a: 0, o: 12345]]
           ]
  end

  # @spec ORD-DATA-005
  test "parses a successful cancel response into confirmation" do
    response = %{
      "status" => "ok",
      "response" => %{"type" => "cancel", "data" => %{"statuses" => ["success"]}}
    }

    assert Ultramoist.Orders.Order.parse_cancel_response(response) == :ok
  end

  test "truncates price to Hyperliquid's tick-size and significant-figure rules" do
    assert Ultramoist.Orders.Order.format_price("50000.123456", 5) == "50000"
    assert Ultramoist.Orders.Order.format_price(50000, 5) == "50000"
  end

  test "truncates size to the asset's size decimals" do
    assert Ultramoist.Orders.Order.format_size("1.23456789", 5) == "1.23456"
    assert Ultramoist.Orders.Order.format_size(0.001, 3) == "0.001"
  end

  test "does not pad size with trailing zeros when it has fewer decimals than allowed" do
    assert Ultramoist.Orders.Order.format_size("0.001", 5) == "0.001"
  end

  # @spec ORD-API-001
  test "places a limit order for a known coin: resolves asset index, signs, submits, returns order id" do
    meta_stub = fn %{"type" => "meta"}, _opts ->
      {:ok, %{"universe" => [%{"name" => "BTC", "szDecimals" => 5}]}}
    end

    {:ok, cache_pid} =
      Ultramoist.AssetCache.start_link(
        base_url: "unused",
        http: {Ultramoist.FakeHttp, stub: meta_stub}
      )

    exchange_stub = fn _action, _opts ->
      {:ok,
       %{
         "status" => "ok",
         "response" => %{
           "type" => "order",
           "data" => %{"statuses" => [%{"resting" => %{"oid" => 99}}]}
         }
       }}
    end

    priv_key = :crypto.hash(:sha256, "order test private key")

    assert Ultramoist.Orders.Order.place_limit(cache_pid, "BTC", true, "1.0", "0.001",
             priv_key: priv_key,
             source: Ultramoist.Signer.testnet_source(),
             http: {Ultramoist.FakeHttp, stub: exchange_stub}
           ) == {:ok, 99}
  end

  # @spec LEV-DATA-002
  test "sets leverage for a known coin: resolves asset index, signs, submits, returns confirmation" do
    meta_stub = fn %{"type" => "meta"}, _opts ->
      {:ok, %{"universe" => [%{"name" => "BTC", "szDecimals" => 5}]}}
    end

    {:ok, cache_pid} =
      Ultramoist.AssetCache.start_link(
        base_url: "unused",
        http: {Ultramoist.FakeHttp, stub: meta_stub}
      )

    exchange_stub = fn _action, _opts ->
      {:ok, %{"status" => "ok", "response" => %{"type" => "default", "data" => %{}}}}
    end

    priv_key = :crypto.hash(:sha256, "leverage test private key")

    assert Ultramoist.Orders.Order.update_leverage(cache_pid, "BTC",
             is_cross: true,
             leverage: 5,
             priv_key: priv_key,
             source: Ultramoist.Signer.testnet_source(),
             http: {Ultramoist.FakeHttp, stub: exchange_stub}
           ) == :ok
  end

  # @spec ORD-API-002
  test "returns a not-found error for an unknown coin without signing or submitting anything" do
    meta_stub = fn %{"type" => "meta"}, _opts ->
      {:ok, %{"universe" => [%{"name" => "BTC", "szDecimals" => 5}]}}
    end

    {:ok, cache_pid} =
      Ultramoist.AssetCache.start_link(
        base_url: "unused",
        http: {Ultramoist.FakeHttp, stub: meta_stub}
      )

    assert Ultramoist.Orders.Order.place_limit(cache_pid, "NOTACOIN", true, "1.0", "0.001", []) ==
             {:error, :not_found}
  end

  # @spec NONCE-API-004
  test "signs and submits using an injected nonce instead of the default allocator" do
    test_pid = self()

    exchange_stub = fn _action, opts ->
      send(test_pid, {:nonce_used, Keyword.fetch!(opts, :nonce)})

      {:ok,
       %{
         "status" => "ok",
         "response" => %{"type" => "cancel", "data" => %{"statuses" => ["success"]}}
       }}
    end

    priv_key = :crypto.hash(:sha256, "order test private key")

    assert Ultramoist.Orders.Order.cancel(
             asset_index: 0,
             order_id: 99,
             priv_key: priv_key,
             source: Ultramoist.Signer.testnet_source(),
             http: {Ultramoist.FakeHttp, stub: exchange_stub},
             nonce: fn -> 424_242 end
           ) == :ok

    assert_received {:nonce_used, 424_242}
  end

  # @spec ORD-API-003
  test "cancels an order: signs, submits, and returns confirmation" do
    exchange_stub = fn _action, _opts ->
      {:ok,
       %{
         "status" => "ok",
         "response" => %{"type" => "cancel", "data" => %{"statuses" => ["success"]}}
       }}
    end

    priv_key = :crypto.hash(:sha256, "order test private key")

    assert Ultramoist.Orders.Order.cancel(
             asset_index: 0,
             order_id: 99,
             priv_key: priv_key,
             source: Ultramoist.Signer.testnet_source(),
             http: {Ultramoist.FakeHttp, stub: exchange_stub}
           ) == :ok
  end
end
