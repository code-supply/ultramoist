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
                Ultramoist.Universe.Asset.parse(Enum.at(universe_meta, 0), Enum.at(contexts, 0)),
                Ultramoist.Universe.Asset.parse(Enum.at(universe_meta, 1), Enum.at(contexts, 1))
              ]}
  end
end
