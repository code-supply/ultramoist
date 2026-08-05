defmodule Ultramoist.MsgpackTest do
  use ExUnit.Case, async: true

  # @spec MPK-DATA-002
  test "encodes a string" do
    assert Ultramoist.Msgpack.encode("abc") == <<0xA3, "abc">>
    assert Ultramoist.Msgpack.encode("hello world") == <<0xAB, "hello world">>
  end

  # @spec MPK-DATA-001
  test "encodes a flat keyword list as a map, in order" do
    assert Ultramoist.Msgpack.encode(a: "x", b: "y") ==
             <<0x82, 0xA1, "a", 0xA1, "x", 0xA1, "b", 0xA1, "y">>
  end

  # @spec MPK-DATA-007
  test "encodes a small positive integer" do
    assert Ultramoist.Msgpack.encode(5) == <<5>>
    assert Ultramoist.Msgpack.encode(100) == <<100>>
  end

  # @spec MPK-DATA-004
  test "encodes a boolean" do
    assert Ultramoist.Msgpack.encode(true) == <<0xC3>>
    assert Ultramoist.Msgpack.encode(false) == <<0xC2>>
  end

  # @spec MPK-DATA-008
  test "encodes a uint8-range integer" do
    assert Ultramoist.Msgpack.encode(200) == <<0xCC, 200>>
    assert Ultramoist.Msgpack.encode(255) == <<0xCC, 255>>
  end

  # @spec MPK-DATA-008
  test "encodes a uint16-range integer" do
    assert Ultramoist.Msgpack.encode(1000) == <<0xCD, 3, 232>>
    assert Ultramoist.Msgpack.encode(60000) == <<0xCD, 234, 96>>
  end

  # @spec MPK-DATA-008
  test "encodes a uint32-range integer" do
    assert Ultramoist.Msgpack.encode(100_000) == <<0xCE, 0, 1, 134, 160>>
    assert Ultramoist.Msgpack.encode(500_000) == <<0xCE, 0, 7, 161, 32>>
  end

  # @spec MPK-DATA-008
  test "encodes a uint64-range integer" do
    assert Ultramoist.Msgpack.encode(5_000_000_000) == <<0xCF, 0, 0, 0, 1, 42, 5, 242, 0>>
  end

  # @spec MPK-DATA-006
  test "encodes a plain list as an array" do
    assert Ultramoist.Msgpack.encode(["a", "b"]) == <<0x92, 0xA1, "a", 0xA1, "b">>
    assert Ultramoist.Msgpack.encode([1, 2, 3]) == <<0x93, 1, 2, 3>>
  end

  # @spec MPK-DATA-005
  test "encodes a nested keyword list as a nested map" do
    assert Ultramoist.Msgpack.encode(a: [b: "x"]) ==
             <<0x81, 0xA1, "a", 0x81, 0xA1, "b", 0xA1, "x">>
  end
end
