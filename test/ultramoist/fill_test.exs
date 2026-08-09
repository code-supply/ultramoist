defmodule Ultramoist.FillTest do
  use ExUnit.Case, async: true

  test "parses a raw fill into named fields, with prices/sizes as Decimal and time as NaiveDateTime" do
    raw = %{
      "coin" => "KAITO",
      "px" => "0.6767",
      "sz" => "18.0",
      "side" => "A",
      "time" => 1_700_000_000_000,
      "startPosition" => "-12795.0",
      "dir" => "Open Short",
      "closedPnl" => "0.0",
      "hash" => "0x1cda6111",
      "oid" => 57_634_902_055,
      "crossed" => true,
      "fee" => "0.0",
      "feeToken" => "USDC",
      "tid" => 852_679_471_752_590,
      "twapId" => nil
    }

    assert Ultramoist.Fill.parse(raw) == %Ultramoist.Fill{
             coin: "KAITO",
             price: Decimal.new("0.6767"),
             size: Decimal.new("18.0"),
             side: "A",
             time: ~N[2023-11-14 22:13:20.000],
             start_position: Decimal.new("-12795.0"),
             direction: "Open Short",
             closed_pnl: Decimal.new("0.0"),
             hash: "0x1cda6111",
             order_id: 57_634_902_055,
             crossed: true,
             fee: Decimal.new("0.0"),
             fee_token: "USDC",
             trade_id: 852_679_471_752_590,
             twap_id: nil
           }
  end
end
