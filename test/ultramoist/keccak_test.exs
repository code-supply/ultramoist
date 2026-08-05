defmodule Ultramoist.KeccakTest do
  use ExUnit.Case, async: true

  # @spec KECC-DATA-001
  test "hashes the empty input" do
    assert Ultramoist.Keccak.hash256(<<>>)
           |> Base.encode16(case: :lower) ==
             "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"
  end

  # @spec KECC-DATA-002
  test "hashes a short known message" do
    assert Ultramoist.Keccak.hash256("abc")
           |> Base.encode16(case: :lower) ==
             "4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45"
  end

  # @spec KECC-DATA-003
  test "hashes input spanning multiple blocks" do
    assert Ultramoist.Keccak.hash256(String.duplicate("a", 200))
           |> Base.encode16(case: :lower) ==
             "96ea54061def936c4be90b518992fdc6f12f535068a256229aca54267b4d084d"
  end
end
