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
end
