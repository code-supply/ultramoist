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
end
