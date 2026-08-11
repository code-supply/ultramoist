defmodule Ultramoist.Positions.Position do
  @moduledoc false

  defstruct [:coin, :size, :entry_price, :unrealized_pnl]

  def parse(%{
        "position" => %{
          "coin" => coin,
          "szi" => szi,
          "entryPx" => entry_px,
          "unrealizedPnl" => unrealized_pnl
        }
      }) do
    %__MODULE__{
      coin: coin,
      size: Decimal.new(szi),
      entry_price: Decimal.new(entry_px),
      unrealized_pnl: Decimal.new(unrealized_pnl)
    }
  end
end
