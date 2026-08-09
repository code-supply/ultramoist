defmodule Ultramoist.FundingPayment do
  @moduledoc false

  defstruct [:coin, :amount, :size, :funding_rate, :sample_count, :time]

  def parse(%{"delta" => delta} = record) do
    %__MODULE__{
      coin: delta["coin"],
      amount: Decimal.new(delta["usdc"]),
      size: Decimal.new(delta["szi"]),
      funding_rate: Decimal.new(delta["fundingRate"]),
      sample_count: delta["nSamples"],
      time: Ultramoist.Timestamp.parse(record["time"])
    }
  end
end
