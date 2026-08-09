defmodule Ultramoist.VaultDetails do
  @moduledoc false

  defstruct [
    :name,
    :vault_address,
    :leader,
    :description,
    :portfolio,
    :apr,
    :follower_state,
    :leader_fraction,
    :leader_commission,
    :followers,
    :max_distributable,
    :max_withdrawable,
    :is_closed,
    :relationship,
    :allow_deposits,
    :always_close_on_withdraw
  ]

  def parse(details) do
    %__MODULE__{
      name: details["name"],
      vault_address: details["vaultAddress"],
      leader: details["leader"],
      description: details["description"],
      portfolio: details["portfolio"],
      apr: Decimal.from_float(details["apr"]),
      follower_state: details["followerState"],
      leader_fraction: Decimal.from_float(details["leaderFraction"]),
      leader_commission: Decimal.from_float(details["leaderCommission"]),
      followers: details["followers"],
      max_distributable: Decimal.from_float(details["maxDistributable"]),
      max_withdrawable: Decimal.from_float(details["maxWithdrawable"]),
      is_closed: details["isClosed"],
      relationship: details["relationship"],
      allow_deposits: details["allowDeposits"],
      always_close_on_withdraw: details["alwaysCloseOnWithdraw"]
    }
  end
end
