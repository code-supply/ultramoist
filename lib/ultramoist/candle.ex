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
      open_time: candle["t"],
      close_time: candle["T"],
      open: candle["o"],
      high: candle["h"],
      low: candle["l"],
      close: candle["c"],
      volume: candle["v"],
      trade_count: candle["n"]
    }
  end
end
