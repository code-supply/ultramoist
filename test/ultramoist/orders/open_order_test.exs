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
      "origSz" => "250",
      "reduceOnly" => false
    }

    assert Ultramoist.Orders.OpenOrder.parse(raw) == %Ultramoist.Orders.OpenOrder{
             coin: "LDO",
             side: "B",
             limit_price: Decimal.new("0.373"),
             size: Decimal.new("100"),
             order_id: 12345,
             timestamp: ~N[2023-11-14 22:13:20.000],
             original_size: Decimal.new("250"),
             reduce_only: false
           }
  end

  # @spec ORD-DATA-021
  test "parses a trigger order's triggerPx into trigger_price" do
    raw = %{
      "coin" => "LDO",
      "side" => "A",
      "limitPx" => "0.373",
      "sz" => "100",
      "oid" => 12345,
      "timestamp" => 1_700_000_000_000,
      "origSz" => "250",
      "reduceOnly" => true,
      "isTrigger" => true,
      "triggerPx" => "0.350"
    }

    assert %Ultramoist.Orders.OpenOrder{trigger_price: %Decimal{} = trigger_price} =
             Ultramoist.Orders.OpenOrder.parse(raw)

    assert Decimal.equal?(trigger_price, Decimal.new("0.350"))
  end

  test "parses a trailing stop as its order type, with no fixed trigger price" do
    raw = %{
      "coin" => "BTC",
      "side" => "A",
      "limitPx" => "109412.0",
      "sz" => "0.001",
      "oid" => 65_786_313_322,
      "timestamp" => 1_795_347_998_539,
      "origSz" => "0.001",
      "reduceOnly" => true,
      "isTrigger" => true,
      "orderType" => "Trailing Stop Market",
      "triggerCondition" => "Activation above 124685, retracement 3117, best waiting",
      "triggerPx" => "0.0"
    }

    assert %Ultramoist.Orders.OpenOrder{
             order_type: "Trailing Stop Market",
             trigger_price: nil,
             reduce_only: true
           } = Ultramoist.Orders.OpenOrder.parse(raw)

    assert %Ultramoist.Orders.OpenOrder{order_type: "Stop Market"} =
             Ultramoist.Orders.OpenOrder.parse(%{
               raw
               | "orderType" => "Stop Market",
                 "triggerPx" => "95000.0"
             })
  end

  # @spec ORD-DATA-018
  test "parses a raw open order's cloid into client_id" do
    raw = %{
      "coin" => "LDO",
      "side" => "B",
      "limitPx" => "0.373",
      "sz" => "100",
      "oid" => 12345,
      "timestamp" => 1_700_000_000_000,
      "origSz" => "250",
      "reduceOnly" => false,
      "cloid" => "0x1234567890abcdef1234567890abcdef"
    }

    assert %Ultramoist.Orders.OpenOrder{client_id: "0x1234567890abcdef1234567890abcdef"} =
             Ultramoist.Orders.OpenOrder.parse(raw)
  end
end
