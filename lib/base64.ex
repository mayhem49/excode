defmodule Base64 do
  # tuple provides O(1) access
  @base64_charset "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
  @base64_table @base64_charset
                |> :binary.bin_to_list()
                # |> Enum.map(fn <<x>> -> x end)
                |> List.to_tuple()

  # A bitstring having total number of bits equal to multiple of 8 is bianry.
  def encode(input, opts \\ []) when is_binary(input) do
    padding? = Keyword.get(opts, :padding, true)
    do_encode(input, <<>>, padding?)
  end

  # works by converting each 3 bytes(24 bits) into 4 sextets(24 bits)
  # we try to match first 24 bits
  # if there are less than 24 bits we need to do padding
  # if last block is of 2 byte(16 bits), make it 18 bits by appending 2 0's at LSB
  # encode 18 bits to 3 sextets, and append `=` as padding
  # if last block is of 1 byte(8 bits), make it 12 bits by appending 4 0's at LSB
  # encode 12 bits to 2 sextets, and append `==` as padding

  defp do_encode(<<>>, result, _padding?), do: result

  defp do_encode(<<block::binary-size(1)>>, result, padding?) do
    <<a::6, b::6>> = <<block::bitstring, 0::4>>
    pad = if padding?, do: "==", else: ""
    encoded_block = <<sextet_to_base64(a), sextet_to_base64(b)>> <> pad

    result <> encoded_block
  end

  defp do_encode(<<block::binary-size(2)>>, result, padding?) do
    <<a::6, b::6, c::6>> = <<block::bitstring, 0::2>>
    pad = if padding?, do: "=", else: ""
    encoded_block = <<sextet_to_base64(a), sextet_to_base64(b), sextet_to_base64(c)>> <> pad
    result <> encoded_block
  end

  defp do_encode(<<block::binary-size(3), rest::binary>>, result, padding?) do
    encoded_block = encode_block(block)
    do_encode(rest, result <> encoded_block, padding?)
  end

  defp encode_block(<<block::binary-size(3)>>) do
    <<a::6, b::6, c::6, d::6>> = block
    <<sextet_to_base64(a), sextet_to_base64(b), sextet_to_base64(c), sextet_to_base64(d)>>
  end

  defp sextet_to_base64(a) do
    elem(@base64_table, a)
  end

  # decode
  # convert four byte to 3 byte
  def decode(input, opts \\ []) do
    padding? = Keyword.get(opts, :padding, true)
    do_decode(input, <<>>, padding?)
  end

  defp do_decode(<<>>, result, _padding?), do: result

  # padless decoding allow multiple strings to decode into same bytes
  # only matters when last block is less than four base64 byte
  # todo: example?
  defp do_decode(<<ab::binary-size(2)>>, result, false) do
    with {:ok, decoded_block} <- do_decode_two_byte(ab) do
      result <> decoded_block
    end
  end

  defp do_decode(<<abc::binary-size(3)>>, result, false) do
    with {:ok, decoded_block} <- do_decode_three_byte(abc) do
      result <> decoded_block
    end
  end

  # when padding is enabled, then no of bytes is multiple of 4 with padding.
  # will decode to 1 byte (12 -> 8 bits)
  defp do_decode(<<ab::binary-size(2), "==">>, result, _padding? = true) do
    do_decode(ab, result, false)
  end

  # will decode to 2 bytes (18 -> 16 bits)
  defp do_decode(<<abc::binary-size(3), "=">>, result, _padding? = true) do
    do_decode(abc, result, false)
  end

  # todo handle whitespace and write test
  defp do_decode(<<block::binary-size(4), rest::binary>>, result, padding?) do
    with {:ok, decoded_block} <- do_decode_four_byte(block) do
      do_decode(rest, result <> decoded_block, padding?)
    end
  end

  # maybe refactor do_decode_*_byte to sigle fucntion to remove manual expansion and instead use Enum functions
  # but it's not too bad, i guess?

  # using 8 instead of binary-size(1), cause it was too verbose
  defp do_decode_two_byte(<<a::8, b::8>>) do
    with {:ok, a} <- base64_to_sextet(a),
         {:ok, b} <- base64_to_sextet(b) do
      <<decoded_block::binary-size(1), _::4>> = <<a::6, b::6>>
      {:ok, decoded_block}
    end
  end

  defp do_decode_three_byte(<<a::8, b::8, c::8>>) do
    with {:ok, a} <- base64_to_sextet(a),
         {:ok, b} <- base64_to_sextet(b),
         {:ok, c} <- base64_to_sextet(c) do
      <<decoded_block::binary-size(2), _::2>> = <<a::6, b::6, c::6>>
      {:ok, decoded_block}
    end
  end

  defp do_decode_four_byte(<<a::8, b::8, c::8, d::8>>) do
    with {:ok, a} <- base64_to_sextet(a),
         {:ok, b} <- base64_to_sextet(b),
         {:ok, c} <- base64_to_sextet(c),
         {:ok, d} <- base64_to_sextet(d) do
      # IO.inspect("#{a} #{b} #{c} #{d}")
      {:ok, <<a::6, b::6, c::6, d::6>>}
    end
  end

  # todo: bench mark against previous version
  def base64_to_sextet(a) do
    a =
      case a do
        # uppercase
        a when a >= ?A and a <= ?Z -> a - ?A
        # lowercase
        a when a >= ?a and a <= ?z -> 26 + a - ?a
        # digits
        a when a >= ?0 and a <= ?9 -> 52 + a - ?0
        # +
        ?+ -> 62
        # /
        ?/ -> 63
        _ -> nil
      end

    if a, do: {:ok, a}, else: {:error, :invalid_base64_encoding}
  end
end
