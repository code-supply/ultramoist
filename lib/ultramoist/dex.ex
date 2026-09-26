defmodule Ultramoist.Dex do
  @moduledoc false

  def asset_id_offset(nil), do: 0
  def asset_id_offset(perp_dex_index), do: 100_000 + perp_dex_index * 10_000

  def index_of(perp_dexs, dex) do
    case Enum.find_index(perp_dexs, &(&1 && &1["name"] == dex)) do
      nil -> {:error, :not_found}
      index -> {:ok, index}
    end
  end
end
