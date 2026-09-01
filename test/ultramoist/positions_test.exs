defmodule Ultramoist.PositionsTest do
  use ExUnit.Case, async: true

  test "fetches a user's positions and parses them into structs" do
    raw = %{
      "position" => %{
        "coin" => "LDO",
        "szi" => "3250.0",
        "entryPx" => "0.29601",
        "unrealizedPnl" => "1.1525",
        "marginUsed" => "241.5",
        "leverage" => %{"type" => "cross", "value" => 20}
      },
      "type" => "oneWay"
    }

    stub = fn %{"type" => "clearinghouseState", "user" => "0xabc"}, _opts ->
      {:ok, %{"assetPositions" => [raw]}}
    end

    assert Ultramoist.Positions.fetch("0xabc",
             base_url: "unused",
             http: {Ultramoist.FakeHttp, stub: stub}
           ) == {:ok, [Ultramoist.Positions.Position.parse(raw)]}
  end

  test "parses a full clearinghouseState payload into positions, account value, and time" do
    raw_position = %{
      "position" => %{
        "coin" => "LDO",
        "szi" => "3250.0",
        "entryPx" => "0.29601",
        "unrealizedPnl" => "1.1525",
        "marginUsed" => "241.5",
        "leverage" => %{"type" => "cross", "value" => 20}
      },
      "type" => "oneWay"
    }

    clearinghouse_state = %{
      "marginSummary" => %{"accountValue" => "1234.56"},
      "time" => 1_724_000_000_000,
      "assetPositions" => [raw_position]
    }

    assert Ultramoist.Positions.parse(clearinghouse_state) == %{
             positions: [
               %Ultramoist.Positions.Position{
                 coin: "LDO",
                 size: Decimal.new("3250.0"),
                 entry_price: Decimal.new("0.29601"),
                 unrealized_pnl: Decimal.new("1.1525"),
                 margin_used: Decimal.new("241.5"),
                 leverage: 20
               }
             ],
             account_value: "1234.56",
             time: 1_724_000_000_000
           }
  end
end
