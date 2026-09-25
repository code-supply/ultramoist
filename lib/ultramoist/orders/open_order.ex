defmodule Ultramoist.Orders.OpenOrder do
  @moduledoc false

  defstruct [
    :coin,
    :side,
    :limit_price,
    :size,
    :order_id,
    :reduce_only,
    :timestamp,
    :original_size
  ]

  def parse(order) do
    %__MODULE__{
      coin: order["coin"],
      side: order["side"],
      limit_price: Decimal.new(order["limitPx"]),
      size: Decimal.new(order["sz"]),
      order_id: order["oid"],
      reduce_only: order["reduceOnly"],
      timestamp: Ultramoist.Timestamp.parse(order["timestamp"]),
      original_size: Decimal.new(order["origSz"])
    }
  end
end
