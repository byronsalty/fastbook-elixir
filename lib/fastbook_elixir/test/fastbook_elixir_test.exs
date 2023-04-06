defmodule FastbookElixirTest do
  use ExUnit.Case
  doctest FastbookElixir

  test "greets the world" do
    assert FastbookElixir.hello() == :world
  end
end
