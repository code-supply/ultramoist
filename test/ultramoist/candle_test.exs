defmodule Ultramoist.CandleTest do
  use ExUnit.Case, async: true

  test "parses a raw candle into named fields" do
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
             open_time: 1_700_000_000_000,
             close_time: 1_700_003_600_000,
             open: "50000.0",
             high: "51000.0",
             low: "49000.0",
             close: "50500.0",
             volume: "12.34",
             trade_count: 42
           }
  end
end
