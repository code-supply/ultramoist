defmodule Ultramoist.Book.Level do
  @moduledoc false

  defstruct [:price, :size]

  def parse(raw) do
    %__MODULE__{price: Decimal.new(raw["px"]), size: Decimal.new(raw["sz"])}
  end
end
