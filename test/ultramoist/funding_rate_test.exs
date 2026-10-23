defmodule Ultramoist.FundingRateTest do
  use ExUnit.Case, async: true

  test "parses a raw funding history entry, with its rate as Decimal and time as NaiveDateTime" do
    raw = %{
      "coin" => "BTC",
      "fundingRate" => "0.0000125",
      "premium" => "-0.0002",
      "time" => 1_700_000_000_042
    }

    assert Ultramoist.FundingRate.parse(raw) == %Ultramoist.FundingRate{
             coin: "BTC",
             funding_rate: Decimal.new("0.0000125"),
             time: ~N[2023-11-14 22:13:20.042]
           }
  end
end
