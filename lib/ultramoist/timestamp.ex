defmodule Ultramoist.Timestamp do
  @moduledoc false

  def parse(nil), do: nil
  def parse(ms), do: ms |> DateTime.from_unix!(:millisecond) |> DateTime.to_naive()
end
