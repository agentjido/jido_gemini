defmodule Jido.Gemini.Mapper do
  @moduledoc """
  Maps Gemini CLI SDK events to Jido.Harness.Event structs.
  """

  alias GeminiCliSdk.Types.{ErrorEvent, InitEvent, MessageEvent, ResultEvent, ToolResultEvent, ToolUseEvent}
  alias Jido.Harness.Event

  @doc """
  Maps a Gemini SDK event into one or more normalized events.
  """
  @spec map_event(term()) :: {:ok, [Event.t()]} | {:error, term()}
  def map_event(%InitEvent{} = event) do
    payload = %{"model" => event.model}
    {:ok, [build_event(:session_started, event.session_id, payload, event)]}
  end

  def map_event(%MessageEvent{role: "assistant"} = event) do
    type = if event.delta == true, do: :output_text_delta, else: :output_text_final
    {:ok, [build_event(type, nil, %{"role" => "assistant", "text" => event.content}, event)]}
  end

  def map_event(%MessageEvent{} = event) do
    {:ok, [build_event(:provider_event, nil, %{"role" => event.role, "text" => event.content}, event)]}
  end

  def map_event(%ToolUseEvent{} = event) do
    payload = %{
      "name" => event.tool_name,
      "input" => event.parameters,
      "call_id" => event.tool_id
    }

    {:ok, [build_event(:tool_call, nil, payload, event)]}
  end

  def map_event(%ToolResultEvent{} = event) do
    payload = %{
      "call_id" => event.tool_id,
      "output" => event.output,
      "error" => event.error,
      "is_error" => event.status != "success"
    }

    {:ok, [build_event(:tool_result, nil, payload, event)]}
  end

  def map_event(%ResultEvent{} = event) do
    if event.status == "success" do
      {:ok,
       [
         build_event(
           :session_completed,
           nil,
           %{"status" => event.status, "stats" => event.stats},
           event
         )
       ]}
    else
      {:ok,
       [
         build_event(
           :session_failed,
           nil,
           %{"status" => event.status, "error" => event.error, "stats" => event.stats},
           event
         )
       ]}
    end
  end

  def map_event(%ErrorEvent{} = event) do
    type = if event.severity == "fatal", do: :session_failed, else: :provider_event

    {:ok,
     [
       build_event(
         type,
         nil,
         %{
           "severity" => event.severity,
           "message" => event.message,
           "kind" => event.kind,
           "details" => event.details
         },
         event
       )
     ]}
  end

  def map_event(other) do
    {:ok, [build_event(:provider_event, nil, %{"value" => inspect(other)}, other)]}
  end

  defp build_event(type, session_id, payload, raw) do
    Event.new!(%{
      type: type,
      provider: :gemini,
      session_id: session_id,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      payload: stringify_keys(payload),
      raw: raw
    })
  end

  defp stringify_keys(map) when is_map(map) do
    map
    |> Enum.map(fn {k, v} -> {to_string(k), stringify_keys(v)} end)
    |> Map.new()
  end

  defp stringify_keys(list) when is_list(list), do: Enum.map(list, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
