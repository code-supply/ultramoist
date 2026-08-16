defmodule Ultramoist.FundingPayment do
  @moduledoc false

  defstruct [:coin, :amount, :size, :funding_rate, :sample_count, :time]

  def parse(%{"delta" => delta} = record), do: parse_fields(delta, record["time"])

  def parse(%{"coin" => _, "usdc" => _, "szi" => _} = record),
    do: parse_fields(record, record["time"])

  defp parse_fields(fields, time) do
    %__MODULE__{
      coin: fields["coin"],
      amount: Decimal.new(fields["usdc"]),
      size: Decimal.new(fields["szi"]),
      funding_rate: Decimal.new(fields["fundingRate"]),
      sample_count: fields["nSamples"],
      time: Ultramoist.Timestamp.parse(time)
    }
  end
end
