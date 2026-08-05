defmodule Ultramoist.Keccak do
  @moduledoc false

  import Bitwise

  @mask64 0xFFFFFFFFFFFFFFFF
  @rate_bytes 136
  @output_bytes 32

  @round_constants [
    0x0000000000000001,
    0x0000000000008082,
    0x800000000000808A,
    0x8000000080008000,
    0x000000000000808B,
    0x0000000080000001,
    0x8000000080008081,
    0x8000000000008009,
    0x000000000000008A,
    0x0000000000000088,
    0x0000000080008009,
    0x000000008000000A,
    0x000000008000808B,
    0x800000000000008B,
    0x8000000000008089,
    0x8000000000008003,
    0x8000000000008002,
    0x8000000000000080,
    0x000000000000800A,
    0x800000008000000A,
    0x8000000080008081,
    0x8000000000008080,
    0x0000000080000001,
    0x8000000080008008
  ]

  @rotation_offsets {
    0,
    1,
    62,
    28,
    27,
    36,
    44,
    6,
    55,
    20,
    3,
    10,
    43,
    25,
    39,
    41,
    45,
    15,
    21,
    8,
    18,
    2,
    61,
    56,
    14
  }

  def hash256(input) when is_binary(input) do
    input
    |> pad(@rate_bytes)
    |> absorb(initial_state())
    |> squeeze(@output_bytes)
  end

  defp initial_state, do: Tuple.duplicate(0, 25)

  defp pad(input, rate) do
    pad_len = rate - rem(byte_size(input), rate)

    if pad_len == 1 do
      input <> <<0x81>>
    else
      input <> <<0x01>> <> :binary.copy(<<0>>, pad_len - 2) <> <<0x80>>
    end
  end

  defp absorb(<<>>, state), do: state

  defp absorb(<<block::binary-size(@rate_bytes), rest::binary>>, state) do
    new_state = state |> xor_block(block) |> keccak_f()
    absorb(rest, new_state)
  end

  defp xor_block(state, block) do
    block
    |> then(fn b -> for <<lane::little-64 <- b>>, do: lane end)
    |> Enum.with_index()
    |> Enum.reduce(state, fn {lane, i}, acc -> put_elem(acc, i, bxor(elem(acc, i), lane)) end)
  end

  defp squeeze(state, output_bytes) do
    lane_count = div(output_bytes + 7, 8)

    0..(lane_count - 1)
    |> Enum.map(&<<elem(state, &1)::little-64>>)
    |> Enum.join()
    |> binary_part(0, output_bytes)
  end

  defp keccak_f(state) do
    Enum.reduce(@round_constants, state, fn rc, s -> round_fn(s, rc) end)
  end

  defp round_fn(state, rc) do
    state
    |> theta()
    |> rho_pi()
    |> chi()
    |> iota(rc)
  end

  defp at(state, x, y), do: elem(state, x + 5 * y)

  defp theta(state) do
    c =
      for x <- 0..4 do
        Enum.reduce(0..4, 0, fn y, acc -> bxor(acc, at(state, x, y)) end)
      end
      |> List.to_tuple()

    d =
      for x <- 0..4 do
        bxor(elem(c, rem(x + 4, 5)), rotl(elem(c, rem(x + 1, 5)), 1))
      end
      |> List.to_tuple()

    for y <- 0..4, x <- 0..4 do
      bxor(at(state, x, y), elem(d, x))
    end
    |> List.to_tuple()
  end

  defp rho_pi(state) do
    for x <- 0..4, y <- 0..4 do
      value = rotl(at(state, x, y), elem(@rotation_offsets, x + 5 * y))
      new_x = y
      new_y = rem(2 * x + 3 * y, 5)
      {new_x + 5 * new_y, value}
    end
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
    |> List.to_tuple()
  end

  defp chi(state) do
    for y <- 0..4, x <- 0..4 do
      a = at(state, x, y)
      b1 = at(state, rem(x + 1, 5), y)
      b2 = at(state, rem(x + 2, 5), y)
      bxor(a, band(bxor(b1, @mask64), b2))
    end
    |> List.to_tuple()
  end

  defp iota(state, rc), do: put_elem(state, 0, bxor(elem(state, 0), rc))

  defp rotl(v, n), do: band(bor(bsl(v, n), bsr(v, 64 - n)), @mask64)
end
