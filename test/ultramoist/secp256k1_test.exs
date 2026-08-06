defmodule Ultramoist.Secp256k1Test do
  use ExUnit.Case, async: true

  @curve_order 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
  @generator_y 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8
  # The generator point's y^2 mod p (i.e. Gx^3 + 7 mod p), independently
  # precomputed rather than derived by the formula under test.
  @generator_y_squared 0x4866D6A5AB41AB2C6BCC57CCD3735DA5F16F80A548E5E20A44E4E9B8118C26F2

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
end
