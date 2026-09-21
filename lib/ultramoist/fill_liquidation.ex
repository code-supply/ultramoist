defmodule Ultramoist.FillLiquidation do
  @moduledoc false

  defstruct [:liquidated_user, :mark_price, :method]

  def parse(nil), do: nil

  def parse(liquidation) do
    %__MODULE__{
      liquidated_user: liquidation["liquidatedUser"],
      mark_price: Decimal.new(liquidation["markPx"]),
      method: liquidation["method"]
    }
  end
end
