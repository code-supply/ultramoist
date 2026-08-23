defmodule Ultramoist.BookTest do
  use ExUnit.Case, async: true

  # @spec SCAN-API-002
  test "fetches a coin's level-2 order book and parses bid/ask levels" do
    raw_levels = [
      [%{"px" => "50000", "sz" => "1.5", "n" => 3}, %{"px" => "49999", "sz" => "2.0", "n" => 2}],
      [%{"px" => "50001", "sz" => "1.2", "n" => 4}, %{"px" => "50002", "sz" => "0.8", "n" => 1}]
    ]

    stub = fn %{"type" => "l2Book", "coin" => "BTC"}, _opts -> {:ok, %{"levels" => raw_levels}} end

    assert Ultramoist.Book.fetch("BTC", base_url: "unused", http: {Ultramoist.FakeHttp, stub: stub}) ==
             {:ok,
              %{
                bids: [
                  %Ultramoist.Book.Level{price: Decimal.new("50000"), size: Decimal.new("1.5")},
                  %Ultramoist.Book.Level{price: Decimal.new("49999"), size: Decimal.new("2.0")}
                ],
                asks: [
                  %Ultramoist.Book.Level{price: Decimal.new("50001"), size: Decimal.new("1.2")},
                  %Ultramoist.Book.Level{price: Decimal.new("50002"), size: Decimal.new("0.8")}
                ]
              }}
  end

  # @spec SCAN-API-002a
  test "returns an error when the coin doesn't exist, rather than a nil book" do
    stub = fn %{"type" => "l2Book", "coin" => "NOTACOIN"}, _opts -> {:ok, nil} end

    assert Ultramoist.Book.fetch("NOTACOIN",
             base_url: "unused",
             http: {Ultramoist.FakeHttp, stub: stub}
           ) == {:error, :not_found}
  end
end
