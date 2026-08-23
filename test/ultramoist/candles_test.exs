defmodule Ultramoist.CandlesTest do
  use ExUnit.Case, async: true

  # @spec CNDL-API-001
  test "fetches and parses a chronological list of candles" do
    raw_candles = [
      %{
        "s" => "BTC",
        "i" => "1h",
        "t" => 1_700_000_000_000,
        "T" => 1_700_003_600_000,
        "o" => "50000",
        "h" => "50500",
        "l" => "49500",
        "c" => "50200",
        "v" => "123.45",
        "n" => 500
      }
    ]

    stub = fn %{"type" => "candleSnapshot", "req" => %{"coin" => "BTC"}}, _opts ->
      {:ok, raw_candles}
    end

    assert Ultramoist.Candles.fetch("BTC", "1h", 1_700_000_000_000, 1_700_003_600_000,
             base_url: "unused",
             http: {Ultramoist.FakeHttp, stub: stub}
           ) ==
             {:ok,
              [
                %Ultramoist.Candle{
                  coin: "BTC",
                  interval: "1h",
                  open_time: ~N[2023-11-14 22:13:20.000],
                  close_time: ~N[2023-11-14 23:13:20.000],
                  open: Decimal.new("50000"),
                  high: Decimal.new("50500"),
                  low: Decimal.new("49500"),
                  close: Decimal.new("50200"),
                  volume: Decimal.new("123.45"),
                  trade_count: 500
                }
              ]}
  end

  # @spec SCAN-API-003a
  test "returns an error for an invalid coin, rather than crashing on a nil response" do
    stub = fn %{"type" => "candleSnapshot", "req" => %{"coin" => "NOTACOIN"}}, _opts ->
      {:ok, nil}
    end

    assert Ultramoist.Candles.fetch("NOTACOIN", "1h", 0, 1000,
             base_url: "unused",
             http: {Ultramoist.FakeHttp, stub: stub}
           ) == {:error, :not_found}
  end
end
