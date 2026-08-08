defmodule Ultramoist.Candle do
  @moduledoc false

  defstruct [
    :coin,
    :interval,
    :open_time,
    :close_time,
    :open,
    :high,
    :low,
    :close,
    :volume,
    :trade_count
  ]

  def parse(candle) do
    %__MODULE__{
      coin: candle["s"],
      interval: candle["i"],
      open_time: Ultramoist.Timestamp.parse(candle["t"]),
      close_time: Ultramoist.Timestamp.parse(candle["T"]),
      open: Decimal.new(candle["o"]),
      high: Decimal.new(candle["h"]),
      low: Decimal.new(candle["l"]),
      close: Decimal.new(candle["c"]),
      volume: Decimal.new(candle["v"]),
      trade_count: candle["n"]
    }
  end
end
