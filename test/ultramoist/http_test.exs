defmodule Ultramoist.HttpTest do
  use ExUnit.Case, async: true

  # @spec HTTP-API-001
  test "makes a generic info request against the real testnet host" do
    assert {:ok, %{"universe" => [%{"name" => _name} | _rest]}} =
             Ultramoist.Http.info_request(%{"type" => "meta"},
               base_url: Ultramoist.Config.info_url(:testnet)
             )
  end

  # @spec HTTP-API-003
  test "makes a stats request against the real testnet host" do
    assert {:ok, [%{"summary" => %{"vaultAddress" => _address}} | _rest]} =
             Ultramoist.Http.stats_request("vaults",
               base_url: Ultramoist.Config.stats_url(:testnet)
             )
  end

  # @spec HTTP-API-002
  test "makes a signed exchange-action request against the real testnet host" do
    action = %{"type" => "cancel", "cancels" => []}

    signature = %{
      "r" => "0x" <> String.duplicate("1", 64),
      "s" => "0x" <> String.duplicate("2", 64),
      "v" => 27
    }

    assert {:ok, %{"status" => "err"}} =
             Ultramoist.Http.exchange_request(action,
               signature: signature,
               nonce: 1,
               vault_address: nil,
               base_url: Ultramoist.Config.info_url(:testnet)
             )
  end
end
