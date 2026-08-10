defmodule Ultramoist.Positions.PositionTest do
  use ExUnit.Case, async: true

  test "parses a position entry from clearinghouseState into coin and signed size" do
    raw = %{"position" => %{"coin" => "LDO", "szi" => "-3250.0"}, "type" => "oneWay"}

    assert Ultramoist.Positions.Position.parse(raw) == %Ultramoist.Positions.Position{
             coin: "LDO",
             size: Decimal.new("-3250.0")
           }
  end
end
