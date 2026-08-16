defmodule Ultramoist.SubscriptionTest do
  use ExUnit.Case, async: true

  # @spec SUB-DATA-001
  test "builds a userFills subscription request and dedup key for a user" do
    assert Ultramoist.Subscription.user_fills("0xabc") ==
             {"userFills:0xabc", %{"type" => "userFills", "user" => "0xabc"}}
  end

  # @spec SUB-DATA-002
  test "builds a clearinghouseState subscription request and dedup key for a user and dex" do
    dex = Ultramoist.Subscription.main_dex()

    assert Ultramoist.Subscription.clearinghouse_state("0xabc", dex) ==
             {"clearinghouseState:0xabc:",
              %{"type" => "clearinghouseState", "user" => "0xabc", "dex" => dex}}
  end

  # @spec SUB-DATA-003
  test "builds a userNonFundingLedgerUpdates subscription request and dedup key for a user" do
    assert Ultramoist.Subscription.user_non_funding_ledger_updates("0xabc") ==
             {"userNonFundingLedgerUpdates:0xabc",
              %{"type" => "userNonFundingLedgerUpdates", "user" => "0xabc"}}
  end

  # @spec SUB-DATA-004
  test "builds a userFundings subscription request and dedup key for a user" do
    assert Ultramoist.Subscription.user_fundings("0xabc") ==
             {"userFundings:0xabc", %{"type" => "userFundings", "user" => "0xabc"}}
  end
end
