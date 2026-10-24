defmodule Ultramoist.PortfolioTest do
  use ExUnit.Case, async: true

  test "fetches a user's portfolio, parsing each period's account value and P&L histories" do
    stub = fn %{"type" => "portfolio", "user" => "0xabc"}, _opts ->
      {:ok,
       [
         [
           "day",
           %{
             "accountValueHistory" => [[1_700_000_000_000, "100.5"]],
             "pnlHistory" => [[1_700_000_000_000, "1.5"]],
             "vlm" => "0.0"
           }
         ],
         [
           "allTime",
           %{
             "accountValueHistory" => [[1_700_000_000_000, "100.5"]],
             "pnlHistory" => [[1_699_913_600_000, "0.0"], [1_700_000_000_000, "-3.25"]],
             "vlm" => "0.0"
           }
         ]
       ]}
    end

    assert {:ok, portfolio} =
             Ultramoist.Portfolio.fetch("0xabc",
               base_url: "unused",
               http: {Ultramoist.FakeHttp, stub: stub}
             )

    assert portfolio["allTime"].pnl_history == [
             {~N[2023-11-13 22:13:20.000], Decimal.new("0.0")},
             {~N[2023-11-14 22:13:20.000], Decimal.new("-3.25")}
           ]

    assert portfolio["day"].account_value_history == [
             {~N[2023-11-14 22:13:20.000], Decimal.new("100.5")}
           ]
  end
end
