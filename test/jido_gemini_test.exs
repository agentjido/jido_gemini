defmodule Jido.GeminiTest do
  use ExUnit.Case, async: false

  alias GeminiCliSdk.Types.{MessageEvent, ResultEvent}

  defmodule StubSdk do
    def execute(_prompt, _opts), do: [%MessageEvent{role: "assistant", content: "ok"}, %ResultEvent{status: "success"}]
  end

  setup do
    old_sdk = Application.get_env(:jido_gemini, :sdk_module)
    Application.put_env(:jido_gemini, :sdk_module, StubSdk)

    on_exit(fn ->
      if old_sdk do
        Application.put_env(:jido_gemini, :sdk_module, old_sdk)
      else
        Application.delete_env(:jido_gemini, :sdk_module)
      end
    end)

    :ok
  end

  test "run/1 returns a stream tuple" do
    assert {:ok, stream} = Jido.Gemini.run("hello")
    events = Enum.to_list(stream)
    assert Enum.any?(events, &(&1.type == :session_completed))
  end
end
