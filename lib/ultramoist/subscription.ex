defmodule Ultramoist.Subscription do
  @moduledoc false

  # @spec SUB-DATA-001
  def user_fills(user) do
    build("userFills", [{"user", user}])
  end

  def main_dex, do: ""

  # @spec SUB-DATA-002
  def clearinghouse_state(user, dex) do
    build("clearinghouseState", [{"user", user}, {"dex", dex}])
  end

  # @spec SUB-DATA-003
  def user_non_funding_ledger_updates(user) do
    build("userNonFundingLedgerUpdates", [{"user", user}])
  end

  # @spec SUB-DATA-004
  def user_fundings(user) do
    build("userFundings", [{"user", user}])
  end

  defp build(type, params) do
    key = Enum.join([type | Enum.map(params, fn {_field, value} -> value end)], ":")
    {key, Map.new([{"type", type} | params])}
  end
end
