defmodule Ultramoist.PositionsTest do
  use ExUnit.Case, async: true

  test "fetches a user's positions and parses them into structs" do
    raw = %{"position" => %{"coin" => "LDO", "szi" => "3250.0"}, "type" => "oneWay"}

    stub = fn %{"type" => "clearinghouseState", "user" => "0xabc"}, _opts ->
      {:ok, %{"assetPositions" => [raw]}}
    end

    assert Ultramoist.Positions.fetch("0xabc",
             base_url: "unused",
             http: {Ultramoist.FakeHttp, stub: stub}
           ) == {:ok, [Ultramoist.Positions.Position.parse(raw)]}
  end
end
