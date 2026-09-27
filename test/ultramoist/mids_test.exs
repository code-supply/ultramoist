defmodule Ultramoist.MidsTest do
  use ExUnit.Case, async: true

  test "fetches a coin's current mid price" do
    stub = fn %{"type" => "allMids"}, _opts -> {:ok, %{"BTC" => "50000.5", "ETH" => "2500.25"}} end

    assert Ultramoist.Mids.fetch("BTC", base_url: "unused", http: {Ultramoist.FakeHttp, stub: stub}) ==
             {:ok, Decimal.new("50000.5")}
  end

  test "returns an error when the coin isn't in the response, rather than crashing" do
    stub = fn %{"type" => "allMids"}, _opts -> {:ok, %{"BTC" => "50000.5"}} end

    assert Ultramoist.Mids.fetch("NOTACOIN",
             base_url: "unused",
             http: {Ultramoist.FakeHttp, stub: stub}
           ) == {:error, :not_found}
  end

  test "returns an error when the response isn't a map at all" do
    stub = fn %{"type" => "allMids"}, _opts -> {:ok, nil} end

    assert Ultramoist.Mids.fetch("BTC", base_url: "unused", http: {Ultramoist.FakeHttp, stub: stub}) ==
             {:error, :not_found}
  end

  test "fetches a builder-deployed dex's mid prices by passing its dex parameter" do
    stub = fn %{"type" => "allMids", "dex" => "xyz"}, _opts ->
      {:ok, %{"xyz:GOLD" => "4281.0"}}
    end

    assert Ultramoist.Mids.fetch("xyz:GOLD",
             base_url: "unused",
             dex: "xyz",
             http: {Ultramoist.FakeHttp, stub: stub}
           ) == {:ok, Decimal.new("4281.0")}
  end

  test "parses a raw mids map into decimal prices" do
    raw = %{"BTC" => "50000.5", "ETH" => "2500.25"}

    assert Ultramoist.Mids.parse(raw) == %{
             "BTC" => Decimal.new("50000.5"),
             "ETH" => Decimal.new("2500.25")
           }
  end
end
