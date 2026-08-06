defmodule Ultramoist.Secp256k1Test do
  use ExUnit.Case, async: true

  @curve_order 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
  @generator_x 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798
  @generator_y 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8
  # The generator point's y^2 mod p (i.e. Gx^3 + 7 mod p), independently
  # precomputed rather than derived by the formula under test.
  @generator_y_squared 0x4866D6A5AB41AB2C6BCC57CCD3735DA5F16F80A548E5E20A44E4E9B8118C26F2

  @double_generator_x 0xC6047F9441ED7D6D3045406E95C07CD85C778E4B8CEF3CA7ABAC09B95C709EE5
  @double_generator_y 0x1AE168FEA63DC339A3C58419466CEAEEF7F632653266D0E1236431A950CFE52A
  @triple_generator_x 0xF9308A019258C31049344F85F89D5229B531C845836F99B08601F113BCE036F9
  @triple_generator_y 0x388F7B0F632DE8140FE337E62A37F3566500A99934C2231B6CB9FD7584B8E672

  @priv_key :crypto.hash(:sha256, "private key")
  @digest Ultramoist.Keccak.hash256("test")

  # @spec SIGN-DATA-001
  test "signs a digest and the signature verifies against the public key" do
    {r, s} = Ultramoist.Secp256k1.sign(@priv_key, @digest)

    der =
      :public_key.der_encode(
        :"ECDSA-Sig-Value",
        {:"ECDSA-Sig-Value", :binary.decode_unsigned(r), :binary.decode_unsigned(s)}
      )

    {pub_key, _priv} = :crypto.generate_key(:ecdh, :secp256k1, @priv_key)

    assert :crypto.verify(:ecdsa, :sha256, {:digest, @digest}, der, [pub_key, :secp256k1])
  end

  # @spec SIGN-DATA-002
  test "normalizes a high s value to curve_order - s" do
    high_s = <<@curve_order - 1::256>>
    assert Ultramoist.Secp256k1.normalize_s(high_s) == <<1::256>>
  end

  # @spec SIGN-DATA-002a
  test "leaves an already-low s value unchanged" do
    low_s = <<1::256>>
    assert Ultramoist.Secp256k1.normalize_s(low_s) == low_s
  end

  # @spec SIGN-DATA-003a
  test "computes the modular square root of a quadratic residue" do
    assert Ultramoist.Secp256k1.mod_sqrt(4) == 2
    assert Ultramoist.Secp256k1.mod_sqrt(@generator_y_squared) == @generator_y
  end

  # @spec SIGN-DATA-003b
  test "adds two distinct points on the curve" do
    g = {@generator_x, @generator_y}
    two_g = {@double_generator_x, @double_generator_y}
    three_g = {@triple_generator_x, @triple_generator_y}

    assert Ultramoist.Secp256k1.point_add(g, two_g) == three_g
  end

  # @spec SIGN-DATA-003b
  test "doubles a point (adds a point to itself)" do
    g = {@generator_x, @generator_y}
    two_g = {@double_generator_x, @double_generator_y}

    assert Ultramoist.Secp256k1.point_add(g, g) == two_g
  end

  # @spec SIGN-DATA-003c
  test "multiplies the generator point by a scalar" do
    g = {@generator_x, @generator_y}
    three_g = {@triple_generator_x, @triple_generator_y}
    assert Ultramoist.Secp256k1.scalar_mult(g, 3) == three_g

    {pub_key, _priv} = :crypto.generate_key(:ecdh, :secp256k1, @priv_key)
    <<4, expected_x::256, expected_y::256>> = pub_key
    priv_key_int = :binary.decode_unsigned(@priv_key)

    assert Ultramoist.Secp256k1.scalar_mult(g, priv_key_int) == {expected_x, expected_y}
  end
end
