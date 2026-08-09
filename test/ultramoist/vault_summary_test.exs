defmodule Ultramoist.VaultSummaryTest do
  use ExUnit.Case, async: true

  test "parses a raw vault summary into named fields, with amounts as Decimal" do
    raw = %{
      "apr" => 0.0079,
      "pnls" => [
        ["day", ["0.0", "1.5"]],
        ["week", ["0.0", "2.5"]],
        ["month", ["0.0", "3.5"]],
        ["allTime", ["0.0", "4.5"]]
      ],
      "summary" => %{
        "createTimeMillis" => 1_736_326_711_359,
        "isClosed" => false,
        "leader" => "0xleader",
        "name" => "HLP",
        "relationship" => %{"type" => "normal"},
        "tvl" => "270.729414",
        "vaultAddress" => "0xvault"
      }
    }

    assert Ultramoist.VaultSummary.parse(raw) == %Ultramoist.VaultSummary{
             vault_address: "0xvault",
             name: "HLP",
             leader: "0xleader",
             tvl: Decimal.new("270.729414"),
             is_closed: false,
             relationship: %{"type" => "normal"},
             create_time: ~N[2025-01-08 08:58:31.359],
             apr: Decimal.from_float(0.0079),
             pnls: %{
               "day" => [Decimal.new("0.0"), Decimal.new("1.5")],
               "week" => [Decimal.new("0.0"), Decimal.new("2.5")],
               "month" => [Decimal.new("0.0"), Decimal.new("3.5")],
               "allTime" => [Decimal.new("0.0"), Decimal.new("4.5")]
             }
           }
  end
end
