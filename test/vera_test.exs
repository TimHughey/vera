defmodule VeraTest do
  use ExUnit.Case
  doctest Vera

  test "greets the world" do
    assert Vera.hello() == :world
  end
end
