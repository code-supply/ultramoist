defmodule Ultramoist.Universe.Asset do
  @moduledoc false

  defstruct [:name, :is_delisted, :day_volume, :mark_price]

  def parse(meta, ctx) do
    %__MODULE__{
      name: meta["name"],
      is_delisted: Map.get(meta, "isDelisted", false),
      day_volume: Decimal.new(ctx["dayNtlVlm"]),
      mark_price: Decimal.new(ctx["markPx"])
    }
  end
end
