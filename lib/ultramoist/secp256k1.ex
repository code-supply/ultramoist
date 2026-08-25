defmodule Ultramoist.Secp256k1 do
  @moduledoc false

  @curve_order 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
  @field_prime 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F
  @generator_x 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798
  @generator_y 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8

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

  def point_add(:infinity, point), do: point
  def point_add(point, :infinity), do: point

  def point_add({x1, y1}, {x1, y1}) do
    slope = Integer.mod(3 * x1 * x1 * mod_inv(2 * y1, @field_prime), @field_prime)
    x3 = Integer.mod(slope * slope - 2 * x1, @field_prime)
    y3 = Integer.mod(slope * (x1 - x3) - y1, @field_prime)
    {x3, y3}
  end

  def point_add({x1, y1}, {x1, y2}) when y1 != y2, do: :infinity

  def point_add({x1, y1}, {x2, y2}) do
    slope = Integer.mod((y2 - y1) * mod_inv(x2 - x1, @field_prime), @field_prime)
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

  def recovery_id(r, s, digest, pub_key) do
    r_int = :binary.decode_unsigned(r)
    s_int = :binary.decode_unsigned(s)
    e = :binary.decode_unsigned(digest)

    y_squared = Integer.mod(r_int * r_int * r_int + 7, @field_prime)
    y = mod_sqrt(y_squared)

    r_inv = mod_inv(r_int, @curve_order)
    u1 = Integer.mod(-e * r_inv, @curve_order)
    u2 = Integer.mod(s_int * r_inv, @curve_order)
    generator = {@generator_x, @generator_y}

    Enum.find(0..1, fn candidate ->
      candidate_y = if Integer.mod(y, 2) == candidate, do: y, else: @field_prime - y
      ephemeral_point = {r_int, candidate_y}

      point_add(scalar_mult(generator, u1), scalar_mult(ephemeral_point, u2)) == pub_key
    end)
  end

  defp mod_inv(a, m) do
    a
    |> Integer.mod(m)
    |> :crypto.mod_pow(m - 2, m)
    |> :binary.decode_unsigned()
  end
end
