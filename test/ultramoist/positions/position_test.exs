defmodule Ultramoist.Positions.PositionTest do
  use ExUnit.Case, async: true

  test "parses a position entry from clearinghouseState into coin, signed size, entry price, unrealized PnL, margin used, leverage, and margin mode" do
    raw = %{
      "position" => %{
        "coin" => "LDO",
        "szi" => "-3250.0",
        "entryPx" => "0.29601",
        "unrealizedPnl" => "-4.9225",
        "marginUsed" => "192.5065",
        "leverage" => %{"type" => "cross", "value" => 10}
      },
      "type" => "oneWay"
    }

    assert Ultramoist.Positions.Position.parse(raw) == %Ultramoist.Positions.Position{
             coin: "LDO",
             size: Decimal.new("-3250.0"),
             entry_price: Decimal.new("0.29601"),
             unrealized_pnl: Decimal.new("-4.9225"),
             margin_used: Decimal.new("192.5065"),
             leverage: 10,
             margin_mode: :cross
           }
  end

  # @spec POS-DATA-001
  test "parses a position's liquidationPx into liquidation_price" do
    raw = %{
      "position" => %{
        "coin" => "LDO",
        "szi" => "-3250.0",
        "entryPx" => "0.29601",
        "unrealizedPnl" => "-4.9225",
        "marginUsed" => "192.5065",
        "leverage" => %{"type" => "cross", "value" => 10},
        "liquidationPx" => "0.35"
      },
      "type" => "oneWay"
    }

    assert %Ultramoist.Positions.Position{liquidation_price: liquidation_price} =
             Ultramoist.Positions.Position.parse(raw)

    assert Decimal.equal?(liquidation_price, Decimal.new("0.35"))
  end
end
