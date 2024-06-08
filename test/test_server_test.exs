defmodule TEST_SERVERTest do
  use ExUnit.Case
  doctest TEST_SERVER

  test "greets the world" do
    assert TEST_SERVER.hello() == :world
  end
end
