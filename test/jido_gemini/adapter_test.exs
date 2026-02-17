defmodule JidoGemini.AdapterTest do
  use ExUnit.Case, async: true

  alias JidoGemini.Adapter

  test "run/2 returns an empty stream for valid input" do
    assert {:ok, stream} = Adapter.run("hello")
    assert Enum.to_list(stream) == []
  end

  test "run/2 accepts keyword options" do
    assert {:ok, stream} = Adapter.run("hello", cwd: "/tmp")
    assert Enum.to_list(stream) == []
  end

  test "run/2 rejects invalid argument types" do
    assert_raise FunctionClauseError, fn -> Adapter.run(:invalid, []) end
    assert_raise FunctionClauseError, fn -> Adapter.run("hello", :invalid) end
  end
end
