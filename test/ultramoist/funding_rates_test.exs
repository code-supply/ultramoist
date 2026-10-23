defmodule Ultramoist.FundingRatesTest do
  use ExUnit.Case, async: true

  alias Ultramoist.FundingRate
  alias Ultramoist.FundingRates

  test "fetches a coin's funding history page by page until a page comes back empty or passes the end, passing errors through" do
    first = %{"coin" => "BTC", "time" => 1_000, "fundingRate" => "0.00001"}
    second = %{"coin" => "BTC", "time" => 2_000, "fundingRate" => "0.00002"}

    stub = fn %{
                "type" => "fundingHistory",
                "coin" => "BTC",
                "startTime" => start,
                "endTime" => 10_000
              },
              _opts ->
      {:ok, Map.fetch!(%{0 => [first, second], 2_001 => []}, start)}
    end

    assert FundingRates.fetch("BTC", 0, 10_000,
             base_url: "unused",
             http: {Ultramoist.FakeHttp, stub: stub}
           ) == {:ok, Enum.map([first, second], &FundingRate.parse/1)}

    third = %{"coin" => "BTC", "time" => 3_000, "fundingRate" => "0.00003"}

    assert FundingRates.fetch("BTC", 0, 10_000,
             base_url: "unused",
             http:
               {Ultramoist.FakeHttp,
                stub: paged_stub(%{0 => [first, second], 2_001 => [third], 3_001 => []})}
           ) == {:ok, Enum.map([first, second, third], &FundingRate.parse/1)}

    beyond_the_end = %{"coin" => "BTC", "time" => 5_000, "fundingRate" => "0.00005"}

    assert FundingRates.fetch("BTC", 0, 4_000,
             base_url: "unused",
             http: {Ultramoist.FakeHttp, stub: paged_stub(%{0 => [first, beyond_the_end]})}
           ) == {:ok, Enum.map([first, beyond_the_end], &FundingRate.parse/1)}

    failing = fn _body, _opts -> {:error, :rate_limited} end

    assert FundingRates.fetch("BTC", 0, 4_000,
             base_url: "unused",
             http: {Ultramoist.FakeHttp, stub: failing}
           ) == {:error, :rate_limited}
  end

  test "pauses between pages of funding history when given a page pause" do
    test_process = self()
    first = %{"coin" => "BTC", "time" => 1_000, "fundingRate" => "0.00001"}
    second = %{"coin" => "BTC", "time" => 2_000, "fundingRate" => "0.00002"}

    {:ok, _rates} =
      FundingRates.fetch("BTC", 0, 10_000,
        base_url: "unused",
        http:
          {Ultramoist.FakeHttp, stub: paged_stub(%{0 => [first], 1_001 => [second], 2_001 => []})},
        page_pause: fn -> send(test_process, :page_paused) end
      )

    assert_received :page_paused
    assert_received :page_paused
    refute_received :page_paused
  end

  defp paged_stub(pages) do
    fn %{"type" => "fundingHistory", "startTime" => start}, _opts ->
      {:ok, Map.fetch!(pages, start)}
    end
  end
end
