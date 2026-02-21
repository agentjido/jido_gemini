defmodule Jido.Gemini.AdapterTest do
  use ExUnit.Case, async: false

  use Jido.Harness.AdapterContract,
    adapter: Jido.Gemini.Adapter,
    provider: :gemini,
    check_run: true,
    run_request: %{prompt: "contract gemini run", cwd: "/repo", metadata: %{}}

  alias GeminiCliSdk.Types.{InitEvent, MessageEvent, ResultEvent}
  alias Jido.Harness.RunRequest
  alias Jido.Gemini.{Adapter, Mapper}

  defmodule StubSdk do
    def execute(prompt, _opts) do
      Application.get_env(:jido_gemini, :stub_gemini_execute, fn _prompt ->
        []
      end).(prompt)
    end

    def run(_prompt, _opts), do: {:ok, "unused"}
  end

  defmodule StubMapper do
    def map_event(event) do
      Application.get_env(:jido_gemini, :stub_gemini_map_event, fn value ->
        Mapper.map_event(value)
      end).(event)
    end
  end

  setup do
    old_sdk = Application.get_env(:jido_gemini, :sdk_module)
    old_execute = Application.get_env(:jido_gemini, :stub_gemini_execute)
    old_mapper = Application.get_env(:jido_gemini, :mapper_module)
    old_map_event = Application.get_env(:jido_gemini, :stub_gemini_map_event)

    Application.put_env(:jido_gemini, :sdk_module, StubSdk)
    Application.put_env(:jido_gemini, :mapper_module, StubMapper)

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
      restore_env(:jido_gemini, :mapper_module, old_mapper)
      restore_env(:jido_gemini, :stub_gemini_map_event, old_map_event)
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
    assert Enum.any?(contract.compatibility_probes, &(&1["command"] == "gemini --help"))

    assert Enum.any?(contract.install_steps, fn step ->
             String.contains?(step["command"], "@google/gemini-cli")
           end)

    assert String.contains?(contract.triage_command_template, "--output-format stream-json")
    assert Adapter.capabilities().cancellation? == false
  end

  test "run/2 maps sdk events to harness events" do
    request = RunRequest.new!(%{prompt: "hello", cwd: "/tmp", metadata: %{}})
    assert {:ok, stream} = Adapter.run(request, [])
    events = Enum.to_list(stream)

    assert_receive {:gemini_execute, "hello"}
    assert Enum.map(events, & &1.type) == [:session_started, :output_text_delta, :session_completed]
    assert Enum.all?(events, &(&1.provider == :gemini))
  end

  test "run/2 emits session_failed events when mapper returns errors" do
    Application.put_env(:jido_gemini, :stub_gemini_map_event, fn _event ->
      {:error, :mapper_failed}
    end)

    request = RunRequest.new!(%{prompt: "hello", cwd: "/tmp", metadata: %{}})
    assert {:ok, stream} = Adapter.run(request, [])
    events = Enum.to_list(stream)

    assert Enum.all?(events, &(&1.type == :session_failed))
    assert Enum.all?(events, &(&1.payload["error"] =~ "mapper_failed"))
  end

  defp restore_env(app, key, nil), do: Application.delete_env(app, key)
  defp restore_env(app, key, value), do: Application.put_env(app, key, value)
end
