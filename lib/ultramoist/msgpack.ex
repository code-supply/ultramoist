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
  @str8_marker 0xD9
  @str16_marker 0xDA
  @str32_marker 0xDB
  @array16_marker 0xDC
  @array32_marker 0xDD
  @map16_marker 0xDE
  @map32_marker 0xDF

  def encode(value) do
    case value do
      true ->
        <<@true_marker>>

      false ->
        <<@false_marker>>

      s when is_binary(s) ->
        encode_string(s)

      n when is_integer(n) ->
        encode_integer(n)

      list when is_list(list) ->
        if Keyword.keyword?(list), do: encode_list(list), else: encode_array(list)
    end
  end

  defp encode_string(s) when byte_size(s) > 65_535, do: <<@str32_marker, byte_size(s)::32>> <> s
  defp encode_string(s) when byte_size(s) > 255, do: <<@str16_marker, byte_size(s)::16>> <> s
  defp encode_string(s) when byte_size(s) > 31, do: <<@str8_marker, byte_size(s)>> <> s
  defp encode_string(s), do: <<@fixstr_marker + byte_size(s)>> <> s

  defp encode_integer(n) when n > 4_294_967_295, do: <<@uint64_marker, n::64>>
  defp encode_integer(n) when n > 65535, do: <<@uint32_marker, n::32>>
  defp encode_integer(n) when n > 255, do: <<@uint16_marker, n::16>>
  defp encode_integer(n) when n > 127, do: <<@uint8_marker, n>>
  defp encode_integer(n), do: <<n>>

  defp encode_list(list) do
    entries = Enum.map(list, fn {k, v} -> encode(to_string(k)) <> encode(v) end)

    collection_header(@fixmap_marker, @map16_marker, @map32_marker, length(list)) <>
      Enum.join(entries)
  end

  defp encode_array(list) do
    entries = Enum.map(list, &encode/1)

    collection_header(@fixarray_marker, @array16_marker, @array32_marker, length(list)) <>
      Enum.join(entries)
  end

  defp collection_header(fix_marker, _marker16, _marker32, count) when count <= 15 do
    <<fix_marker + count>>
  end

  defp collection_header(_fix_marker, marker16, _marker32, count) when count <= 65535 do
    <<marker16, count::16>>
  end

  defp collection_header(_fix_marker, _marker16, marker32, count) do
    <<marker32, count::32>>
  end
end
