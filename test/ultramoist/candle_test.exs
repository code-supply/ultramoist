defmodule Ultramoist.CandleTest do
  use ExUnit.Case, async: true

  test "parses a raw candle into named fields, with timestamps and prices as proper types" do
    raw = %{
      "s" => "BTC",
      "i" => "1h",
      "t" => 1_700_000_000_000,
      "T" => 1_700_003_600_000,
      "o" => "50000.0",
      "h" => "51000.0",
      "l" => "49000.0",
      "c" => "50500.0",
      "v" => "12.34",
      "n" => 42
    }

    assert Ultramoist.Candle.parse(raw) == %Ultramoist.Candle{
             coin: "BTC",
             interval: "1h",
             open_time: ~N[2023-11-14 22:13:20.000],
             close_time: ~N[2023-11-14 23:13:20.000],
             open: Decimal.new("50000.0"),
             high: Decimal.new("51000.0"),
             low: Decimal.new("49000.0"),
             close: Decimal.new("50500.0"),
             volume: Decimal.new("12.34"),
             trade_count: 42
           }
  end

  test "parses a nil close_time for an in-progress candle" do
    raw = %{
      "s" => "BTC",
      "i" => "1h",
      "t" => 1_700_000_000_000,
      "T" => nil,
      "o" => "50000.0",
      "h" => "51000.0",
      "l" => "49000.0",
      "c" => "50500.0",
      "v" => "12.34",
      "n" => 42
    }

    assert %Ultramoist.Candle{close_time: nil} = Ultramoist.Candle.parse(raw)
  end
end
