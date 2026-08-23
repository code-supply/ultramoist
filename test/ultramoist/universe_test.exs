defmodule Ultramoist.UniverseTest do
  use ExUnit.Case, async: true

  # @spec SCAN-API-001
  test "fetches the meta+asset-context universe and parses it into structs, zipped by position" do
    universe_meta = [
      %{"name" => "BTC", "szDecimals" => 5},
      %{"name" => "OLDCOIN", "szDecimals" => 2, "isDelisted" => true}
    ]

    contexts = [
      %{"dayNtlVlm" => "1000000", "markPx" => "50000"},
      %{"dayNtlVlm" => "500", "markPx" => "1"}
    ]

    stub = fn %{"type" => "metaAndAssetCtxs"}, _opts ->
      {:ok, [%{"universe" => universe_meta}, contexts]}
    end

    assert Ultramoist.Universe.fetch(base_url: "unused", http: {Ultramoist.FakeHttp, stub: stub}) ==
             {:ok,
              [
                %Ultramoist.Universe.Asset{
                  name: "BTC",
                  is_delisted: false,
                  day_volume: Decimal.new("1000000"),
                  mark_price: Decimal.new("50000")
                },
                %Ultramoist.Universe.Asset{
                  name: "OLDCOIN",
                  is_delisted: true,
                  day_volume: Decimal.new("500"),
                  mark_price: Decimal.new("1")
                }
              ]}
  end
end
