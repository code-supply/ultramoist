defmodule Ultramoist.NonceAllocatorTest do
  use ExUnit.Case, async: true

  alias Ultramoist.NonceAllocator

  # @spec NONCE-DATA-001
  test "advances to the current time when it's already ahead of the last issued nonce" do
    assert NonceAllocator.next_nonce(1_700_000_000_000, 1_700_000_000_500) ==
             1_700_000_000_500
  end

  # @spec NONCE-DATA-001
  test "bumps one past the last issued nonce when the current time hasn't moved past it" do
    assert NonceAllocator.next_nonce(1_700_000_000_500, 1_700_000_000_500) ==
             1_700_000_000_501

    assert NonceAllocator.next_nonce(1_700_000_000_500, 1_700_000_000_100) ==
             1_700_000_000_501
  end

  # @spec NONCE-API-001
  # @spec NONCE-API-002
  test "issues strictly increasing nonces from a fresh allocator even when the clock repeats" do
    ref = NonceAllocator.new()

    first = NonceAllocator.next(ref, 1_700_000_000_000)
    second = NonceAllocator.next(ref, 1_700_000_000_000)
    third = NonceAllocator.next(ref, 1_700_000_000_000)

    assert [first, second, third] == Enum.sort([first, second, third])
    assert length(Enum.uniq([first, second, third])) == 3
  end

  # @spec NONCE-API-002
  test "never hands out a duplicate nonce across many concurrent callers sharing one allocator" do
    ref = NonceAllocator.new()

    nonces =
      1..200
      |> Task.async_stream(fn _ -> NonceAllocator.next(ref, System.system_time(:millisecond)) end,
        max_concurrency: 50
      )
      |> Enum.map(fn {:ok, nonce} -> nonce end)

    assert length(nonces) == length(Enum.uniq(nonces))
  end
end
