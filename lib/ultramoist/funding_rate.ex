defmodule Ultramoist.FundingRate do
  @moduledoc false

  defstruct [:coin, :funding_rate, :time]

  def parse(%{"coin" => coin, "fundingRate" => funding_rate, "time" => time}) do
    %__MODULE__{
      coin: coin,
      funding_rate: Decimal.new(funding_rate),
      time: Ultramoist.Timestamp.parse(time)
    }
  end
end
