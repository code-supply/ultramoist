defmodule Ultramoist.Universe.Asset do
  @moduledoc false

  defstruct [:name, :dex, :is_delisted, :day_volume, :mark_price]

  def parse(meta, ctx, dex \\ nil) do
    %__MODULE__{
      name: meta["name"],
      dex: dex,
      is_delisted: Map.get(meta, "isDelisted", false),
      day_volume: Decimal.new(ctx["dayNtlVlm"]),
      mark_price: Decimal.new(ctx["markPx"])
    }
  end
end
