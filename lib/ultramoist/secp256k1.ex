defmodule Ultramoist.Secp256k1 do
  @moduledoc false

  @curve_order 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
  @field_prime 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F

  def sign(priv_key, digest) do
    der = :crypto.sign(:ecdsa, :sha256, {:digest, digest}, [priv_key, :secp256k1])
    {:"ECDSA-Sig-Value", r, s} = :public_key.der_decode(:"ECDSA-Sig-Value", der)
    {<<r::256>>, <<s::256>>}
  end

  def normalize_s(s) do
    s_int = :binary.decode_unsigned(s)

    if s_int > div(@curve_order, 2) do
      <<@curve_order - s_int::256>>
    else
      s
    end
  end

  def mod_sqrt(a) do
    :crypto.mod_pow(a, div(@field_prime + 1, 4), @field_prime) |> :binary.decode_unsigned()
  end

  def point_add({x1, y1}, {x1, y1}) do
    slope = Integer.mod(3 * x1 * x1 * mod_inv(2 * y1), @field_prime)
    x3 = Integer.mod(slope * slope - 2 * x1, @field_prime)
    y3 = Integer.mod(slope * (x1 - x3) - y1, @field_prime)
    {x3, y3}
  end

  def point_add({x1, y1}, {x2, y2}) do
    slope = Integer.mod((y2 - y1) * mod_inv(x2 - x1), @field_prime)
    x3 = Integer.mod(slope * slope - x1 - x2, @field_prime)
    y3 = Integer.mod(slope * (x1 - x3) - y1, @field_prime)
    {x3, y3}
  end

  def scalar_mult(point, k) when k > 0 do
    [_leading_one | rest_bits] = Integer.digits(k, 2)

    Enum.reduce(rest_bits, point, fn bit, acc ->
      doubled = point_add(acc, acc)
      if bit == 1, do: point_add(doubled, point), else: doubled
    end)
  end

  defp mod_inv(a) do
    a
    |> Integer.mod(@field_prime)
    |> :crypto.mod_pow(@field_prime - 2, @field_prime)
    |> :binary.decode_unsigned()
  end
end
