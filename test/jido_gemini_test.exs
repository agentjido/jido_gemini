defmodule JidoGeminiTest do
  use ExUnit.Case, async: true

  test "run/1 returns a stream tuple" do
    assert {:ok, stream} = JidoGemini.run("hello")
    assert Enum.to_list(stream) == []
  end
end
