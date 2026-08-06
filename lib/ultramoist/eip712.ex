defmodule Ultramoist.Eip712 do
  @moduledoc false

  alias Ultramoist.Keccak

  @domain_type_hash Keccak.hash256(
                      "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    )
  @name_hash Keccak.hash256("Exchange")
  @version_hash Keccak.hash256("1")
  @chain_id 1337
  @verifying_contract <<0::160>>

  @agent_type_hash Keccak.hash256("Agent(string source,bytes32 connectionId)")

  def domain_separator do
    Keccak.hash256(
      @domain_type_hash <>
        @name_hash <>
        @version_hash <>
        <<@chain_id::256>> <>
        <<0::96>> <> @verifying_contract
    )
  end

  def agent_struct_hash(source, connection_id) do
    Keccak.hash256(@agent_type_hash <> Keccak.hash256(source) <> connection_id)
  end

  def signing_digest(domain_separator, struct_hash) do
    Keccak.hash256(<<0x19, 0x01>> <> domain_separator <> struct_hash)
  end
end
