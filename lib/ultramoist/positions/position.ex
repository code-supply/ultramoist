defmodule Ultramoist.Positions.Position do
  @moduledoc false

  defstruct [:coin, :size, :entry_price, :unrealized_pnl, :margin_used]

  def parse(%{
        "position" => %{
          "coin" => coin,
          "szi" => szi,
          "entryPx" => entry_px,
          "unrealizedPnl" => unrealized_pnl,
          "marginUsed" => margin_used
        }
      }) do
    %__MODULE__{
      coin: coin,
      size: Decimal.new(szi),
      entry_price: Decimal.new(entry_px),
      unrealized_pnl: Decimal.new(unrealized_pnl),
      margin_used: Decimal.new(margin_used)
    }
  end
end
