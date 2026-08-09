defmodule Ultramoist.VaultSummary do
  @moduledoc false

  defstruct [
    :vault_address,
    :name,
    :leader,
    :tvl,
    :is_closed,
    :relationship,
    :create_time,
    :apr,
    :pnls
  ]

  def parse(%{"apr" => apr, "pnls" => pnls, "summary" => summary}) do
    %__MODULE__{
      vault_address: summary["vaultAddress"],
      name: summary["name"],
      leader: summary["leader"],
      tvl: Decimal.new(summary["tvl"]),
      is_closed: summary["isClosed"],
      relationship: summary["relationship"],
      create_time: Ultramoist.Timestamp.parse(summary["createTimeMillis"]),
      apr: Decimal.from_float(apr),
      pnls: Map.new(pnls, fn [window, values] -> {window, Enum.map(values, &Decimal.new/1)} end)
    }
  end
end
