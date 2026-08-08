defmodule Ultramoist.OrderTest do
  use ExUnit.Case, async: true

  # @spec ORD-DATA-001
  test "builds a GTC limit-order action from an asset index, side, price, and size" do
    assert Ultramoist.Order.build_place_action(0, true, "100.5", "0.1") == [
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

    assert Ultramoist.Order.parse_place_response(response) == {:ok, 12345}
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

    assert Ultramoist.Order.parse_place_response(response) ==
             {:error, "Price must be divisible by tick size."}
  end

  # @spec ORD-DATA-004
  test "builds a cancel action from an asset index and order id" do
    assert Ultramoist.Order.build_cancel_action(0, 12345) == [
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

    assert Ultramoist.Order.parse_cancel_response(response) == :ok
  end

  test "truncates price to Hyperliquid's tick-size and significant-figure rules" do
    assert Ultramoist.Order.format_price("50000.123456", 5) == "50000"
    assert Ultramoist.Order.format_price(50000, 5) == "50000"
  end

  test "truncates size to the asset's size decimals" do
    assert Ultramoist.Order.format_size("1.23456789", 5) == "1.23456"
    assert Ultramoist.Order.format_size(0.001, 3) == "0.001"
  end

  test "does not pad size with trailing zeros when it has fewer decimals than allowed" do
    assert Ultramoist.Order.format_size("0.001", 5) == "0.001"
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

    assert Ultramoist.Order.place_limit(cache_pid, "BTC", true, "1.0", "0.001",
             priv_key: priv_key,
             source: Ultramoist.Signer.testnet_source(),
             http: {Ultramoist.FakeHttp, stub: exchange_stub}
           ) == {:ok, 99}
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

    assert Ultramoist.Order.place_limit(cache_pid, "NOTACOIN", true, "1.0", "0.001", []) ==
             {:error, :not_found}
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

    assert Ultramoist.Order.cancel(
             asset_index: 0,
             order_id: 99,
             priv_key: priv_key,
             source: Ultramoist.Signer.testnet_source(),
             http: {Ultramoist.FakeHttp, stub: exchange_stub}
           ) == :ok
  end
end
