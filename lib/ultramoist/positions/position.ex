defmodule Ultramoist.Positions.Position do
  @moduledoc false

  defstruct [
    :coin,
    :size,
    :entry_price,
    :unrealized_pnl,
    :margin_used,
    :leverage,
    :margin_mode,
    :liquidation_price
  ]

  def parse(%{
        "position" =>
          %{
            "coin" => coin,
            "szi" => szi,
            "entryPx" => entry_px,
            "unrealizedPnl" => unrealized_pnl,
            "marginUsed" => margin_used,
            "leverage" => %{"type" => margin_mode, "value" => leverage}
          } = position
      }) do
    %__MODULE__{
      coin: coin,
      size: Decimal.new(szi),
      entry_price: Decimal.new(entry_px),
      unrealized_pnl: Decimal.new(unrealized_pnl),
      margin_used: Decimal.new(margin_used),
      leverage: leverage,
      margin_mode: String.to_existing_atom(margin_mode),
      liquidation_price: liquidation_price(position["liquidationPx"])
    }
  end

  defp liquidation_price(nil), do: nil
  defp liquidation_price(liquidation_px), do: Decimal.new(liquidation_px)
end
