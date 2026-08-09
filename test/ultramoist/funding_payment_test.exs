defmodule Ultramoist.FundingPaymentTest do
  use ExUnit.Case, async: true

  test "parses a raw funding payment into named fields, with amounts as Decimal and time as NaiveDateTime" do
    raw = %{
      "delta" => %{
        "coin" => "SOL",
        "fundingRate" => "-0.0000336294",
        "nSamples" => 3,
        "szi" => "267.01",
        "type" => "funding",
        "usdc" => "0.69433"
      },
      "hash" => "0x0000000000000000000000000000000000000000000000000000000000000000",
      "time" => 1_700_000_000_000
    }

    assert Ultramoist.FundingPayment.parse(raw) == %Ultramoist.FundingPayment{
             coin: "SOL",
             amount: Decimal.new("0.69433"),
             size: Decimal.new("267.01"),
             funding_rate: Decimal.new("-0.0000336294"),
             sample_count: 3,
             time: ~N[2023-11-14 22:13:20.000]
           }
  end

  test "parses a nil sample_count" do
    raw = %{
      "delta" => %{
        "coin" => "SOL",
        "fundingRate" => "-0.0000336294",
        "nSamples" => nil,
        "szi" => "267.01",
        "type" => "funding",
        "usdc" => "0.69433"
      },
      "hash" => "0x0000000000000000000000000000000000000000000000000000000000000000",
      "time" => 1_700_000_000_000
    }

    assert %Ultramoist.FundingPayment{sample_count: nil} = Ultramoist.FundingPayment.parse(raw)
  end
end
