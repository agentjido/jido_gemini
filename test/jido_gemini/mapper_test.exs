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

  test "map_event/2 threads session_id to non-init events" do
    event = %MessageEvent{role: "assistant", content: "hi", delta: false}
    assert {:ok, [mapped]} = Mapper.map_event(event, "sess-42")
    assert mapped.session_id == "sess-42"
    assert mapped.type == :output_text_final
  end

  test "map_event/1 maps result success events" do
    event = %ResultEvent{status: "success"}
    assert {:ok, [mapped]} = Mapper.map_event(event)
    assert mapped.type == :session_completed
  end

  test "map_event/2 emits flat usage event via UsageEvent.build for result with stats" do
    stats = %GeminiCliSdk.Types.Stats{input_tokens: 100, output_tokens: 50, total_tokens: 150, duration_ms: 1200}
    event = %ResultEvent{status: "success", stats: stats}
    assert {:ok, [usage, completed]} = Mapper.map_event(event, "sess-7")

    assert usage.type == :usage
    assert usage.session_id == "sess-7"
    assert usage.payload["input_tokens"] == 100
    assert usage.payload["output_tokens"] == 50
    assert usage.payload["total_tokens"] == 150
    assert usage.payload["duration_ms"] == 1200
    refute Map.has_key?(usage.payload, "usage")

    assert completed.type == :session_completed
    assert completed.session_id == "sess-7"
  end

  test "map_event/2 preserves canonical usage fields for map-shaped stats" do
    stats = %{"input_tokens" => 10, "output_tokens" => 4, "total_tokens" => 20, "duration_ms" => 300}
    event = %ResultEvent{status: "success", stats: stats}

    assert {:ok, [usage, completed]} = Mapper.map_event(event, "sess-8")

    assert usage.type == :usage
    assert usage.payload["input_tokens"] == 10
    assert usage.payload["output_tokens"] == 4
    assert usage.payload["total_tokens"] == 20
    assert usage.payload["duration_ms"] == 300
    assert completed.type == :session_completed
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
