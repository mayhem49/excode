defmodule ExcodeTest do
  use ExUnit.Case
  doctest Excode

  test "greets the world" do
    assert Excode.hello() == :world
  end
end
