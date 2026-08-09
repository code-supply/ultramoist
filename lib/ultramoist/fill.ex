defmodule Ultramoist.Fill do
  @moduledoc false

  defstruct [
    :coin,
    :price,
    :size,
    :side,
    :time,
    :start_position,
    :direction,
    :closed_pnl,
    :hash,
    :order_id,
    :crossed,
    :fee,
    :fee_token,
    :trade_id,
    :twap_id
  ]

  def parse(fill) do
    %__MODULE__{
      coin: fill["coin"],
      price: Decimal.new(fill["px"]),
      size: Decimal.new(fill["sz"]),
      side: fill["side"],
      time: Ultramoist.Timestamp.parse(fill["time"]),
      start_position: Decimal.new(fill["startPosition"]),
      direction: fill["dir"],
      closed_pnl: Decimal.new(fill["closedPnl"]),
      hash: fill["hash"],
      order_id: fill["oid"],
      crossed: fill["crossed"],
      fee: Decimal.new(fill["fee"]),
      fee_token: fill["feeToken"],
      trade_id: fill["tid"],
      twap_id: fill["twapId"]
    }
  end
end
