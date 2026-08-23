defmodule Ultramoist.OrdersTest do
  use ExUnit.Case, async: true

  # @spec ORDS-API-001
  test "fetches a user's open orders and parses them into structs" do
    raw = %{
      "coin" => "LDO",
      "side" => "B",
      "limitPx" => "0.373",
      "sz" => "100",
      "oid" => 12345,
      "timestamp" => 1_700_000_000_000,
      "origSz" => "250"
    }

    stub = fn %{"type" => "openOrders", "user" => "0xabc"}, _opts -> {:ok, [raw]} end

    assert Ultramoist.Orders.fetch_open("0xabc",
             base_url: "unused",
             http: {Ultramoist.FakeHttp, stub: stub}
           ) == {:ok, [Ultramoist.Orders.OpenOrder.parse(raw)]}
  end

  # @spec ORDS-API-002
  test "treats a nil response as no open orders, rather than crashing" do
    stub = fn %{"type" => "openOrders", "user" => "0xabc"}, _opts -> {:ok, nil} end

    assert Ultramoist.Orders.fetch_open("0xabc",
             base_url: "unused",
             http: {Ultramoist.FakeHttp, stub: stub}
           ) == {:ok, []}
  end
end
