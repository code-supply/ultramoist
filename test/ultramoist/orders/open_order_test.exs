defmodule Ultramoist.Orders.OpenOrderTest do
  use ExUnit.Case, async: true

  test "parses a raw open order into named fields, with prices and size as Decimal and timestamp as NaiveDateTime" do
    raw = %{
      "coin" => "LDO",
      "side" => "B",
      "limitPx" => "0.373",
      "sz" => "100",
      "oid" => 12345,
      "timestamp" => 1_700_000_000_000,
      "origSz" => "250"
    }

    assert Ultramoist.Orders.OpenOrder.parse(raw) == %Ultramoist.Orders.OpenOrder{
             coin: "LDO",
             side: "B",
             limit_price: Decimal.new("0.373"),
             size: Decimal.new("100"),
             order_id: 12345,
             timestamp: ~N[2023-11-14 22:13:20.000],
             original_size: Decimal.new("250")
           }
  end
end
