defmodule Ultramoist.Msgpack do
  @moduledoc false

  @fixstr_marker 0xA0
  @fixmap_marker 0x80
  @fixarray_marker 0x90
  @false_marker 0xC2
  @true_marker 0xC3
  @uint8_marker 0xCC
  @uint16_marker 0xCD
  @uint32_marker 0xCE
  @uint64_marker 0xCF

  def encode(value) do
    case value do
      true -> <<@true_marker>>
      false -> <<@false_marker>>
      s when is_binary(s) -> <<@fixstr_marker + byte_size(s)>> <> s
      n when is_integer(n) -> encode_integer(n)
      list when is_list(list) ->
        if Keyword.keyword?(list), do: encode_list(list), else: encode_array(list)
    end
  end

  defp encode_integer(n) when n > 4_294_967_295, do: <<@uint64_marker, n::64>>
  defp encode_integer(n) when n > 65535, do: <<@uint32_marker, n::32>>
  defp encode_integer(n) when n > 255, do: <<@uint16_marker, n::16>>
  defp encode_integer(n) when n > 127, do: <<@uint8_marker, n>>
  defp encode_integer(n), do: <<n>>

  defp encode_list(list) do
    entries = Enum.map(list, fn {k, v} -> encode(to_string(k)) <> encode(v) end)
    <<@fixmap_marker + length(list)>> <> Enum.join(entries)
  end

  defp encode_array(list) do
    entries = Enum.map(list, &encode/1)
    <<@fixarray_marker + length(list)>> <> Enum.join(entries)
  end
end
