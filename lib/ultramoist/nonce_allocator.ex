defmodule Ultramoist.NonceAllocator do
  @moduledoc false

  @persistent_term_key {__MODULE__, :ref}

  # @spec NONCE-DATA-001
  def next_nonce(last_nonce, now_ms), do: max(last_nonce + 1, now_ms)

  # @spec NONCE-API-001
  def new, do: :atomics.new(1, signed: true)

  # @spec NONCE-API-002
  def next(ref, now_ms) do
    last_nonce = :atomics.get(ref, 1)
    candidate = next_nonce(last_nonce, now_ms)

    case :atomics.compare_exchange(ref, 1, last_nonce, candidate) do
      :ok -> candidate
      _actual -> next(ref, now_ms)
    end
  end

  # @spec NONCE-API-003
  def next_from_default_allocator do
    next(default_ref(), System.system_time(:millisecond))
  end

  defp default_ref do
    case :persistent_term.get(@persistent_term_key, nil) do
      nil ->
        ref = new()
        :persistent_term.put(@persistent_term_key, ref)
        ref

      ref ->
        ref
    end
  end
end
