defmodule Jido.Gemini.AdapterTest do
  use ExUnit.Case, async: false

  alias GeminiCliSdk.Types.{InitEvent, MessageEvent, ResultEvent}
  alias Jido.Harness.RunRequest
  alias Jido.Gemini.Adapter

  defmodule StubSdk do
    def execute(prompt, _opts) do
      Application.get_env(:jido_gemini, :stub_gemini_execute, fn _prompt ->
        []
      end).(prompt)
    end

    def run(_prompt, _opts), do: {:ok, "unused"}
  end

  setup do
    old_sdk = Application.get_env(:jido_gemini, :sdk_module)
    old_execute = Application.get_env(:jido_gemini, :stub_gemini_execute)

    Application.put_env(:jido_gemini, :sdk_module, StubSdk)

    Application.put_env(:jido_gemini, :stub_gemini_execute, fn prompt ->
      send(self(), {:gemini_execute, prompt})

      [
        %InitEvent{session_id: "gem-1", model: "gemini-2.5"},
        %MessageEvent{role: "assistant", content: "hello", delta: true},
        %ResultEvent{status: "success"}
      ]
    end)

    on_exit(fn ->
      restore_env(:jido_gemini, :sdk_module, old_sdk)
      restore_env(:jido_gemini, :stub_gemini_execute, old_execute)
    end)

    :ok
  end

  test "id/0 and capabilities/0" do
    assert Adapter.id() == :gemini
    caps = Adapter.capabilities()
    assert caps.streaming? == true
    assert caps.tool_calls? == true
  end

  test "runtime_contract/0 exposes gemini runtime requirements" do
    contract = Adapter.runtime_contract()
    assert contract.provider == :gemini
    assert "GEMINI_API_KEY" in contract.host_env_required_any
    assert "gemini" in contract.runtime_tools_required
  end

  test "run/2 maps sdk events to harness events" do
    request = RunRequest.new!(%{prompt: "hello", cwd: "/tmp", metadata: %{}})
    assert {:ok, stream} = Adapter.run(request, [])
    events = Enum.to_list(stream)

    assert_receive {:gemini_execute, "hello"}
    assert Enum.map(events, & &1.type) == [:session_started, :output_text_delta, :session_completed]
    assert Enum.all?(events, &(&1.provider == :gemini))
  end

  defp restore_env(app, key, nil), do: Application.delete_env(app, key)
  defp restore_env(app, key, value), do: Application.put_env(app, key, value)
end
