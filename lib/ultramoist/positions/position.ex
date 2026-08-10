defmodule Ultramoist.Positions.Position do
  @moduledoc false

  defstruct [:coin, :size]

  def parse(%{"position" => %{"coin" => coin, "szi" => szi}}) do
    %__MODULE__{coin: coin, size: Decimal.new(szi)}
  end
end
