defmodule Ultramoist.VaultDetailsTest do
  use ExUnit.Case, async: true

  test "parses a raw vault details response into named fields, with ratios as Decimal" do
    raw = %{
      "name" => "Hyperliquidity Provider (HLP)",
      "vaultAddress" => "0xa15099a30bbf2e68942d6f4c43d70d04faeab0a0",
      "leader" => "0x1defb2ff28e5b5c6a6b8c637e7f8c1d5e6b4a3f2",
      "description" => "HLP",
      "portfolio" => [["day", %{"accountValueHistory" => [], "pnlHistory" => [], "vlm" => "0.0"}]],
      "apr" => 0.007916620129395608,
      "followerState" => %{"user" => "0x35b62d2e738235ad668f15b51aaa37d947523910"},
      "leaderFraction" => 6.652530702376941e-7,
      "leaderCommission" => 0.0,
      "followers" => [%{"user" => "0x06fd8cfc02980d08ca47ba721422f7e74597e59a"}],
      "maxDistributable" => 0.0,
      "maxWithdrawable" => 2965.947668,
      "isClosed" => false,
      "relationship" => %{"type" => "parent", "data" => %{"childAddresses" => []}},
      "allowDeposits" => true,
      "alwaysCloseOnWithdraw" => false
    }

    assert Ultramoist.VaultDetails.parse(raw) == %Ultramoist.VaultDetails{
             name: "Hyperliquidity Provider (HLP)",
             vault_address: "0xa15099a30bbf2e68942d6f4c43d70d04faeab0a0",
             leader: "0x1defb2ff28e5b5c6a6b8c637e7f8c1d5e6b4a3f2",
             description: "HLP",
             portfolio: [
               ["day", %{"accountValueHistory" => [], "pnlHistory" => [], "vlm" => "0.0"}]
             ],
             apr: Decimal.from_float(0.007916620129395608),
             follower_state: %{"user" => "0x35b62d2e738235ad668f15b51aaa37d947523910"},
             leader_fraction: Decimal.from_float(6.652530702376941e-7),
             leader_commission: Decimal.from_float(0.0),
             followers: [%{"user" => "0x06fd8cfc02980d08ca47ba721422f7e74597e59a"}],
             max_distributable: Decimal.from_float(0.0),
             max_withdrawable: Decimal.from_float(2965.947668),
             is_closed: false,
             relationship: %{"type" => "parent", "data" => %{"childAddresses" => []}},
             allow_deposits: true,
             always_close_on_withdraw: false
           }
  end

  test "parses a nil follower_state when the requesting user does not follow the vault" do
    raw = %{
      "name" => "Hyperliquidity Provider (HLP)",
      "vaultAddress" => "0xa15099a30bbf2e68942d6f4c43d70d04faeab0a0",
      "leader" => "0x1defb2ff28e5b5c6a6b8c637e7f8c1d5e6b4a3f2",
      "description" => "HLP",
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

    assert %Ultramoist.VaultDetails{follower_state: nil} = Ultramoist.VaultDetails.parse(raw)
  end
end
