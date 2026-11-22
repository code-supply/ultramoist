defmodule Ultramoist.VaultsTest do
  use ExUnit.Case, async: true

  test "fetches a user's fills for a vault and parses them into structs" do
    raw = %{
      "coin" => "LDO",
      "px" => "0.373",
      "sz" => "100",
      "side" => "B",
      "time" => 1000,
      "startPosition" => "0",
      "dir" => "Open Long",
      "closedPnl" => "0",
      "hash" => "0xabc",
      "oid" => 1,
      "crossed" => false,
      "fee" => "0",
      "feeToken" => "USDC",
      "tid" => 1,
      "twapId" => nil
    }

    stub = fn %{
                "type" => "userFillsByTime",
                "user" => "0xabc",
                "startTime" => 1,
                "endTime" => 2
              },
              _opts ->
      {:ok, [raw]}
    end

    assert Ultramoist.Vaults.fetch_fills("0xabc", 1, 2,
             base_url: "unused",
             http: {Ultramoist.FakeHttp, stub: stub}
           ) == {:ok, [Ultramoist.Fill.parse(raw)]}
  end

  test "fetches a user's funding payments for a vault and parses them into structs" do
    raw = %{
      "delta" => %{
        "coin" => "SOL",
        "usdc" => "1.23",
        "szi" => "10.5",
        "fundingRate" => "0.0000125",
        "nSamples" => 24,
        "type" => "funding"
      },
      "time" => 1000
    }

    stub = fn %{
                "type" => "userFunding",
                "user" => "0xabc",
                "startTime" => 1,
                "endTime" => 2
              },
              _opts ->
      {:ok, [raw]}
    end

    assert Ultramoist.Vaults.fetch_funding("0xabc", 1, 2,
             base_url: "unused",
             http: {Ultramoist.FakeHttp, stub: stub}
           ) == {:ok, [Ultramoist.FundingPayment.parse(raw)]}
  end

  test "fetches a vault's details for a given user and parses them into a struct" do
    raw = %{
      "name" => "HLP",
      "vaultAddress" => "0xvault",
      "leader" => "0xleader",
      "description" => "",
      "portfolio" => [],
      "apr" => 0.0,
      "followerState" => nil,
      "leaderFraction" => 0.0,
      "leaderCommission" => 0.0,
      "followers" => [],
      "maxDistributable" => 0.0,
      "maxWithdrawable" => 0.0,
      "isClosed" => false,
      "relationship" => %{"type" => "normal"},
      "allowDeposits" => true,
      "alwaysCloseOnWithdraw" => false
    }

    stub = fn %{"type" => "vaultDetails", "vaultAddress" => "0xvault", "user" => "0xabc"},
              _opts ->
      {:ok, raw}
    end

    assert Ultramoist.Vaults.fetch_details("0xvault", "0xabc",
             base_url: "unused",
             http: {Ultramoist.FakeHttp, stub: stub}
           ) == {:ok, Ultramoist.VaultDetails.parse(raw)}
  end

  test "fetches vault summaries from the stats endpoint and parses them into structs" do
    raw = %{
      "apr" => 0.0079,
      "pnls" => [["day", ["0.0", "1.5"]]],
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

    stub = fn "vaults", _opts -> {:ok, [raw]} end

    assert Ultramoist.Vaults.fetch_summaries(
             base_url: "unused",
             http: {Ultramoist.FakeHttp, stub: stub}
           ) == {:ok, [Ultramoist.VaultSummary.parse(raw)]}
  end

  test "fetches a user's raw vault equities" do
    raw = [%{"vaultAddress" => "0xvault", "equity" => "1.0"}]
    stub = fn %{"type" => "userVaultEquities", "user" => "0xabc"}, _opts -> {:ok, raw} end

    assert Ultramoist.Vaults.fetch_equities("0xabc",
             base_url: "unused",
             http: {Ultramoist.FakeHttp, stub: stub}
           ) == {:ok, raw}
  end

  test "fetches a user's raw non-funding ledger updates" do
    raw = [%{"delta" => %{"type" => "vaultDeposit"}}]

    stub = fn %{"type" => "userNonFundingLedgerUpdates", "user" => "0xabc", "startTime" => 1},
              _opts ->
      {:ok, raw}
    end

    assert Ultramoist.Vaults.fetch_ledger_updates("0xabc", 1,
             base_url: "unused",
             http: {Ultramoist.FakeHttp, stub: stub}
           ) == {:ok, raw}
  end

  test "signals stop when a fill page is under the cap" do
    page = [fill(tid: 1, time: 100)]

    assert Ultramoist.Vaults.fill_pagination_state(page) == :stop
  end

  test "signals continue with the next start time when a fill page hits the cap" do
    page = for i <- 1..2000, do: fill(tid: i, time: i)

    assert Ultramoist.Vaults.fill_pagination_state(page) == {:continue, 2000}
  end

  test "merges multiple fill pages and dedupes by trade id" do
    page1 = for i <- 1..2000, do: fill(tid: i, time: i)
    # The endpoint's startTime is inclusive, so the real API's next page
    # always repeats the previous page's last fill (tid 2000 here).
    page2 = [fill(tid: 2000, time: 2000), fill(tid: 2001, time: 2001)]

    fills = Ultramoist.Vaults.merge_fill_pages([page1, page2])

    assert length(fills) == 2001
    assert fills |> Enum.map(& &1.trade_id) |> Enum.uniq() |> length() == 2001
  end

  defp fill(tid: tid, time: time) do
    %Ultramoist.Fill{
      trade_id: tid,
      time: time |> DateTime.from_unix!(:millisecond) |> DateTime.to_naive()
    }
  end

  test "signals stop when a funding page is under the cap" do
    page = [funding_payment(time: 100, coin: "SOL")]

    assert Ultramoist.Vaults.funding_pagination_state(page) == :stop
  end

  test "signals continue with the next start time when a funding page hits the cap" do
    page = for i <- 1..500, do: funding_payment(time: i, coin: "COIN#{i}")

    assert Ultramoist.Vaults.funding_pagination_state(page) == {:continue, 500}
  end

  test "merges multiple funding pages and dedupes by time and coin" do
    page1 = for i <- 1..500, do: funding_payment(time: i, coin: "COIN#{i}")
    # The endpoint's startTime is inclusive, so the real API's next page
    # always repeats every record from the previous page's last timestamp.
    page2 = [
      funding_payment(time: 500, coin: "COIN500"),
      funding_payment(time: 501, coin: "COIN501")
    ]

    payments = Ultramoist.Vaults.merge_funding_pages([page1, page2])

    assert length(payments) == 501
    assert payments |> Enum.map(&{&1.time, &1.coin}) |> Enum.uniq() |> length() == 501
  end

  defp funding_payment(time: time, coin: coin) do
    %Ultramoist.FundingPayment{
      coin: coin,
      time: time |> DateTime.from_unix!(:millisecond) |> DateTime.to_naive()
    }
  end

  test "walks pagination until a fills page is under the cap, merging the results across pages" do
    first_page = for i <- 1..2000, do: raw_fill(tid: i, time: i)
    second_page = [raw_fill(tid: 2000, time: 2000), raw_fill(tid: 2001, time: 2001)]

    stub = fn
      %{"type" => "userFillsByTime", "user" => "0xabc", "startTime" => 1, "endTime" => 3000},
      _opts ->
        {:ok, first_page}

      %{
        "type" => "userFillsByTime",
        "user" => "0xabc",
        "startTime" => 2000,
        "endTime" => 3000
      },
      _opts ->
        {:ok, second_page}
    end

    assert {:ok, fills} =
             Ultramoist.Vaults.fetch_fills("0xabc", 1, 3000,
               base_url: "unused",
               http: {Ultramoist.FakeHttp, stub: stub}
             )

    trade_ids = Enum.map(fills, & &1.trade_id)
    assert Enum.sort(trade_ids) == Enum.to_list(1..2001)
  end

  defp raw_fill(tid: tid, time: time) do
    %{
      "coin" => "LDO",
      "px" => "0.373",
      "sz" => "100",
      "side" => "B",
      "time" => time,
      "startPosition" => "0",
      "dir" => "Open Long",
      "closedPnl" => "0",
      "hash" => "0xabc",
      "oid" => 1,
      "crossed" => false,
      "fee" => "0",
      "feeToken" => "USDC",
      "tid" => tid,
      "twapId" => nil
    }
  end

  test "walks pagination until a funding page is under the cap, merging the results across pages" do
    first_page = for i <- 1..500, do: raw_funding_payment(time: i, coin: "COIN#{i}")

    second_page = [
      raw_funding_payment(time: 500, coin: "COIN500"),
      raw_funding_payment(time: 501, coin: "COIN501")
    ]

    stub = fn
      %{"type" => "userFunding", "user" => "0xabc", "startTime" => 1, "endTime" => 3000},
      _opts ->
        {:ok, first_page}

      %{"type" => "userFunding", "user" => "0xabc", "startTime" => 500, "endTime" => 3000},
      _opts ->
        {:ok, second_page}
    end

    assert {:ok, payments} =
             Ultramoist.Vaults.fetch_funding("0xabc", 1, 3000,
               base_url: "unused",
               http: {Ultramoist.FakeHttp, stub: stub}
             )

    coins = Enum.map(payments, & &1.coin)
    assert Enum.sort(coins) == Enum.sort(for i <- 1..501, do: "COIN#{i}")
  end

  defp raw_funding_payment(time: time, coin: coin) do
    %{
      "delta" => %{
        "coin" => coin,
        "usdc" => "1.23",
        "szi" => "10.5",
        "fundingRate" => "0.0000125",
        "nSamples" => 24,
        "type" => "funding"
      },
      "time" => time
    }
  end
end
