defmodule Ultramoist.DexTest do
  use ExUnit.Case, async: true

  describe "merge_dex/2" do
    test "leaves a request body unchanged for the native dex" do
      assert Ultramoist.Dex.merge_dex(%{"type" => "allMids"}, nil) == %{"type" => "allMids"}
    end

    test "adds a dex field to a request body for a builder-deployed dex" do
      assert Ultramoist.Dex.merge_dex(%{"type" => "allMids"}, "xyz") == %{
               "type" => "allMids",
               "dex" => "xyz"
             }
    end
  end

  describe "asset_id_offset/1" do
    test "has no offset for the native dex" do
      assert Ultramoist.Dex.asset_id_offset(nil) == 0
    end

    test "offsets a builder-deployed dex's asset ids per Hyperliquid's HIP-3 addressing scheme" do
      assert Ultramoist.Dex.asset_id_offset(1) == 110_000
    end
  end

  describe "index_of/2" do
    test "finds a named dex's position in the perpDexs response" do
      perp_dexs = [nil, %{"name" => "xyz"}, %{"name" => "flx"}]

      assert Ultramoist.Dex.index_of(perp_dexs, "flx") == {:ok, 2}
    end

    test "reports an unknown dex name as not found" do
      perp_dexs = [nil, %{"name" => "xyz"}]

      assert Ultramoist.Dex.index_of(perp_dexs, "nope") == {:error, :not_found}
    end
  end
end
