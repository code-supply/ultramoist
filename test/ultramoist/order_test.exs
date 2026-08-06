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

  # @spec ORD-API-001
  test "places a limit order for a known coin: resolves asset index, signs, submits, returns order id" do
    {:ok, cache_pid} =
      Ultramoist.AssetCache.start_link(base_url: Ultramoist.Config.info_url(:testnet))

    Req.Test.stub(Ultramoist.OrderTest, fn conn ->
      Req.Test.json(conn, %{
        "status" => "ok",
        "response" => %{
          "type" => "order",
          "data" => %{"statuses" => [%{"resting" => %{"oid" => 99}}]}
        }
      })
    end)

    priv_key = :crypto.hash(:sha256, "order test private key")

    assert Ultramoist.Order.place_limit(cache_pid, "BTC", true, "1.0", "0.001",
             priv_key: priv_key,
             source: Ultramoist.Signer.testnet_source(),
             base_url: "https://api.hyperliquid-testnet.xyz",
             plug: {Req.Test, Ultramoist.OrderTest}
           ) == {:ok, 99}
  end
end
