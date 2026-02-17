defmodule JidoGemini.MapperTest do
  use ExUnit.Case, async: true

  alias JidoGemini.Mapper

  test "map_event/1 returns input map for now" do
    event = %{"type" => "output_text_delta", "text" => "hello"}

    assert {:ok, mapped} = Mapper.map_event(event)
    assert mapped == event
  end

  test "map_event/1 returns error for non-map events" do
    assert {:error, :invalid_event} = Mapper.map_event(:invalid)
  end
end
