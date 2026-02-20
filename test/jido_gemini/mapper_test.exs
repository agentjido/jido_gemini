defmodule Jido.Gemini.MapperTest do
  use ExUnit.Case, async: true

  alias GeminiCliSdk.Types.{InitEvent, MessageEvent, ResultEvent}
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
end
