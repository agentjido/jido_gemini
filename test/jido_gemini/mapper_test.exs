defmodule Jido.Gemini.MapperTest do
  use ExUnit.Case, async: true

  alias GeminiCliSdk.Types.{ErrorEvent, InitEvent, MessageEvent, ResultEvent, ToolResultEvent, ToolUseEvent}
  alias Jido.Gemini.Mapper

  test "map_event/1 maps init events" do
    event = %InitEvent{session_id: "gem-1", model: "gemini-2.5-pro"}
    assert {:ok, [mapped]} = Mapper.map_event(event)
    assert mapped.type == :session_started
    assert mapped.provider == :gemini
  end

  test "map_event/1 maps assistant messages" do
    event = %MessageEvent{role: "assistant", content: "hello", delta: true}
    assert {:ok, [mapped]} = Mapper.map_event(event)
    assert mapped.type == :output_text_delta
    assert mapped.payload["text"] == "hello"
  end

  test "map_event/1 maps result success events" do
    event = %ResultEvent{status: "success"}
    assert {:ok, [mapped]} = Mapper.map_event(event)
    assert mapped.type == :session_completed
  end

  test "map_event/1 maps tool calls and results" do
    tool_use = %ToolUseEvent{tool_id: "tool_1", tool_name: "Read", parameters: %{"path" => "README.md"}}
    tool_result = %ToolResultEvent{tool_id: "tool_1", output: "ok", status: "success"}

    assert {:ok, [mapped_use]} = Mapper.map_event(tool_use)
    assert mapped_use.type == :tool_call
    assert mapped_use.payload["call_id"] == "tool_1"

    assert {:ok, [mapped_result]} = Mapper.map_event(tool_result)
    assert mapped_result.type == :tool_result
    assert mapped_result.payload["is_error"] == false
  end

  test "map_event/1 maps error events based on severity" do
    fatal_event = %ErrorEvent{severity: "fatal", message: "failed", kind: "runtime", details: %{}}
    non_fatal = %ErrorEvent{severity: "warn", message: "warning", kind: "runtime", details: %{}}

    assert {:ok, [fatal]} = Mapper.map_event(fatal_event)
    assert fatal.type == :session_failed

    assert {:ok, [warning]} = Mapper.map_event(non_fatal)
    assert warning.type == :provider_event
  end

  test "map_event/1 falls back for unknown messages" do
    assert {:ok, [mapped]} = Mapper.map_event(%{unknown: true})
    assert mapped.type == :provider_event
    assert mapped.payload["value"] =~ "unknown"
  end
end
