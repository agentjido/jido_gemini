defmodule JidoGeminiTest do
  use ExUnit.Case, async: true

  test "run/1 returns not yet implemented" do
    assert {:error, "not yet implemented"} = JidoGemini.run("hello")
  end
end
