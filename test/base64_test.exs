defmodule Base64Test do
  use ExUnit.Case
  @base64_charset "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

  @strings_to_check [
    # long string
    "adfjlasjfl;asjfkjaskdfljasjjfasdlf;kas",
    # perfectly aligned string (6 characters)
    "ABCDEF",
    # last block with 2 characters (padding needed)
    "ABCDE",
    # last block with 3 characters (no padding)
    "ABCD",
    # 3 characters (no padding)
    "ABC",
    # 2 characters (padding needed)
    "AB",
    # 1 character (padding needed)
    "A",
    # 0 characters (empty string)
    "",
    # 5 characters (padding needed)
    "Hello",
    # 6 characters (no padding)
    "OpenAI",
    # 6 characters (no padding)
    "Elixir",
    # 3 characters (no padding)
    "123",
    # 5 characters (padding needed)
    "12345",
    # 7 characters (padding needed)
    "abcdefg",
    # 1 character (padding needed)
    "X",
    # 8 characters (no padding)
    "12345678",
    "&(*)&%^)(@&$*",
    "   ",
    # non ascii, unicode
    # Regular string with Unicode characters
    "Hello, world! 🌍",
    # Japanese characters
    "こんにちは",
    # Chinese characters
    "你好",
    # Cyrillic characters (Russian)
    "Привет",
    # Korean characters
    "안녕하세요",
    # Spanish with emoji
    "¡Hola, mundo! 😊",
    # Hebrew characters
    "שלום",
    # Emojis
    "🙂🙃"
  ]

  test "performs encoding" do
    strings_to_check = @strings_to_check

    Enum.each(strings_to_check, fn str ->
      assert Base.encode64(str) == Base64.encode(str)
    end)
  end

  test "performs encoding without padding" do
    strings_to_check = @strings_to_check

    Enum.each(strings_to_check, fn str ->
      assert Base.encode64(str, padding: false) == Base64.encode(str, padding: false)
    end)
  end

  test "performs decoding of base64 string with padding" do
    str = "abcdef"
    encoded_str = Base64.encode(str, padding: true)
    assert {:ok, str} == Base64.decode(encoded_str, padding: true)

    strings_to_check = @strings_to_check

    Enum.each(strings_to_check, fn str ->
      encoded_str = Base64.encode(str, padding: true)
      assert {:ok, str} == Base64.decode(encoded_str, padding: true)
    end)
  end

  test "performs decoding of base64 string without padding" do
    str = "abcdef"
    encoded_str = Base64.encode(str, padding: false)
    assert {:ok, str} == Base64.decode(encoded_str, padding: false)

    strings_to_check = @strings_to_check

    Enum.each(strings_to_check, fn str ->
      # just fun
      encoder_fun = Enum.random([&Base.encode64/2, &Base64.encode/2])
      encoded_str = encoder_fun.(str, padding: false)
      assert {:ok, str} == Base64.decode(encoded_str, padding: false)
    end)
  end

  @invalid_base64_strings [
    "==ab",
    "=abc",
    # Contains invalid special characters
    "abc$%^",
    # completely invalid
    "!!!!!",
    # Space inside a Base64 string
    "ABCD EFGH",
    # Invalid character '@' in encoded string
    "aGVsbG8@",
    # Triple padding, which is invalid
    "YQ==="
  ]
  test "returns error when invalid base64 string is decoded" do
    Enum.each(@invalid_base64_strings, fn invalid_str ->
      assert {:error, _} = Base64.decode(invalid_str)
    end)
  end

  test "raises runtime error on using decode! api" do
    assert_raise RuntimeError, fn ->
      Base64.decode!(Enum.random(@invalid_base64_strings))
    end
  end

  @excessive_padding [
    # More than two '=' at the end
    "YQ====",
    # Even more excessive padding
    "YQ======",
    # Excess padding in a valid base64 sequence
    "abcd===="
  ]

  test "rejects excessive and unneccesary padding at the end" do
    Enum.each(@excessive_padding, fn invalid_str ->
      assert {:error, _} = Base64.decode(invalid_str)
    end)
  end

  test "rejects base64 string with non-zero-padded bytes for string of length 3n+1 " do
    # when string with length 3n+1 are encoded, first 3n characters are encoded into 4n sextets
    # but the remaining 1 charcter is encoded to  2 sextets(with 4 bits padding and then two padding sextets (`=`))
    # since for second sextet, the last four bits are 0
    # Only following sextets(or base64 characters are valid) are valid
    # 00_0000 (A), 01_0000 (Q)
    # 10_0000 (g), 11_0000 (w)
    valid_chars = ["A", "Q", "g", "w"]

    invalid_chars =
      @base64_charset
      |> String.replace(valid_chars, "")
      |> String.split("", trim: true)

    strings = ["char", "strings"]
    # padding true

    Enum.each(strings, fn string ->
      result =
        string
        |> Base64.encode()
        |> change_nth_byte_from_last(invalid_chars, 3)
        |> Base64.decode()

      assert {:error, _} = result
    end)

    # no padding
    Enum.each(strings, fn string ->
      result =
        string
        |> Base64.encode(padding: false)
        |> change_last_byte(invalid_chars)
        |> Base64.decode(padding: false)

      assert {:error, _} = result
    end)
  end

  test "rejects base64 string with non-zero-padded bytes for string of length 3n+2 " do
    # when string with length 3n+2 are encoded, first 3n characters are encoded into 4n characters
    # but the remaining 2 charcter(16 bits) is encoded 3 sextets(with 2 bits padding and  one padding character (`=`))
    # since for third sextet, the last two bits are 0
    # following sextets(or base64 characters are invalid) are valid
    # `****00` 
    valid_chars = [
      "A",
      "E",
      "I",
      "M",
      "Q",
      "U",
      "Y",
      "c",
      "g",
      "k",
      "o",
      "s",
      "w",
      "0",
      "4",
      "8",
      "+"
    ]

    invalid_chars =
      @base64_charset
      |> String.replace(valid_chars, "")
      |> String.split("", trim: true)

    strings = ["ch", "nepal", "encoding"]

    # padding true
    Enum.each(strings, fn string ->
      result =
        string
        |> Base64.encode()
        |> change_nth_byte_from_last(invalid_chars, 2)
        |> Base64.decode()

      assert {:error, _} = result
    end)

    # padding false
    Enum.each(strings, fn string ->
      result =
        string
        |> Base64.encode(padding: false)
        |> change_last_byte(invalid_chars)
        |> Base64.decode(padding: false)

      assert {:error, _} = result
    end)
  end

  # used to alter last byte of unpadded base64 string 
  # the invalid bytes are list of invalid base64 bytes corr. to 3n+1 or 3n+2 original string
  defp change_last_byte(binary, invalid_bytes) when is_binary(binary) do
    change_nth_byte_from_last(binary, invalid_bytes, 1)
  end

  defp change_nth_byte_from_last(binary, invalid_bytes, i) when is_binary(binary) do
    # returns size of binary in the multiple of 8(rounded-up)
    length = byte_size(binary)
    invalid_char = Enum.random(invalid_bytes)
    # as stated above, we just need to change the second last character to anything except A Q g w
    <<start::binary-size(length - i), _, rest::binary-size(i - 1)>> = binary
    <<start::binary, invalid_char::binary, rest::binary>>
  end
end
