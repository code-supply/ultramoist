defmodule Ultramoist.Eip712Test do
  use ExUnit.Case, async: true

  # @spec EIP-DATA-001
  test "computes the domain separator hash" do
    assert Ultramoist.Eip712.domain_separator()
           |> Base.encode16(case: :lower) ==
             "d79297fcdf2ffcd4ae223d01edaa2ba214ff8f401d7c9300d995d17c82aa4040"
  end

  # @spec EIP-DATA-002
  test "computes the Agent struct hash" do
    connection_id =
      Base.decode16!("9c22ff5f21f0b81b113e63f7db6da94fedef11b2119b4088b89664fb9a3cb658",
        case: :lower
      )

    assert Ultramoist.Eip712.agent_struct_hash("a", connection_id)
           |> Base.encode16(case: :lower) ==
             "8d021d4053b5f59edcdd03ecfaf80272296e48e53c6a53b30eac81621ed0f18f"

    assert Ultramoist.Eip712.agent_struct_hash("b", connection_id)
           |> Base.encode16(case: :lower) ==
             "827ed992eb87f0fe4fcb33da98331924d9f3a9e06546ec8a663f23cd65bb1f3f"
  end

  # @spec EIP-DATA-003
  test "combines domain separator and struct hash into the final signing digest" do
    domain_separator = Ultramoist.Eip712.domain_separator()

    struct_hash_a =
      Base.decode16!("8d021d4053b5f59edcdd03ecfaf80272296e48e53c6a53b30eac81621ed0f18f",
        case: :lower
      )

    struct_hash_b =
      Base.decode16!("827ed992eb87f0fe4fcb33da98331924d9f3a9e06546ec8a663f23cd65bb1f3f",
        case: :lower
      )

    assert Ultramoist.Eip712.signing_digest(domain_separator, struct_hash_a)
           |> Base.encode16(case: :lower) ==
             "74a3f9095de0eeee89fed78889ebe31660c3c8b8725de315a555fff2bf23b24f"

    assert Ultramoist.Eip712.signing_digest(domain_separator, struct_hash_b)
           |> Base.encode16(case: :lower) ==
             "3d7887407aebaaccc99da0c9f1f623a082803c1b99d25d3cae453dbc0ddb0a0b"
  end
end
