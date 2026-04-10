defmodule Jido.Gemini.Mapper do
  @moduledoc """
  Maps Gemini CLI SDK events to Jido.Harness.Event structs.
  """

  alias GeminiCliSdk.Types.{ErrorEvent, InitEvent, MessageEvent, ResultEvent, ToolResultEvent, ToolUseEvent}
  alias Jido.Harness.Event
  alias Jido.Harness.Event.Usage, as: UsageEvent

  @doc """
  Maps a Gemini SDK event into one or more normalized events.

  An optional `session_id` (binary) may be passed so that events lacking their
  own session identifier (e.g. `ResultEvent`) still carry the correct id.
  The adapter is responsible for extracting the session_id from `InitEvent`
  and threading it through subsequent calls.
  """
  @spec map_event(term(), String.t() | nil) :: {:ok, [Event.t()]} | {:error, term()}
  def map_event(event, session_id \\ nil)

  def map_event(%InitEvent{} = event, _session_id) do
    payload = %{"model" => event.model}
    {:ok, [build_event(:session_started, event.session_id, payload, event)]}
  end

  def map_event(%MessageEvent{role: "assistant"} = event, session_id) do
    type = if event.delta == true, do: :output_text_delta, else: :output_text_final
    {:ok, [build_event(type, session_id, %{"role" => "assistant", "text" => event.content}, event)]}
  end

  # Emit user messages so the prompt shows in the UI
  def map_event(%MessageEvent{role: "user"} = event, session_id) do
    {:ok, [build_event(:user_message, session_id, %{"role" => "user", "text" => event.content}, event)]}
  end

  def map_event(%MessageEvent{} = event, session_id) do
    {:ok, [build_event(:provider_event, session_id, %{"role" => event.role, "text" => event.content}, event)]}
  end

  def map_event(%ToolUseEvent{} = event, session_id) do
    payload = %{
      "name" => event.tool_name,
      "input" => event.parameters,
      "call_id" => event.tool_id
    }

    {:ok, [build_event(:tool_call, session_id, payload, event)]}
  end

  def map_event(%ToolResultEvent{} = event, session_id) do
    payload = %{
      "call_id" => event.tool_id,
      "output" => event.output,
      "error" => event.error,
      "is_error" => event.status != "success"
    }

    {:ok, [build_event(:tool_result, session_id, payload, event)]}
  end

  def map_event(%ResultEvent{} = event, session_id) do
    usage_event = maybe_usage_event(event.stats, session_id, event)

    session_event =
      if event.status == "success" do
        build_event(
          :session_completed,
          session_id,
          %{"status" => event.status, "stats" => event.stats},
          event
        )
      else
        build_event(
          :session_failed,
          session_id,
          %{"status" => event.status, "error" => event.error, "stats" => event.stats},
          event
        )
      end

    {:ok, List.wrap(usage_event) ++ [session_event]}
  end

  def map_event(%ErrorEvent{} = event, session_id) do
    type = if event.severity == "fatal", do: :session_failed, else: :provider_event

    {:ok,
     [
       build_event(
         type,
         session_id,
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

  def map_event(other, session_id) do
    {:ok, [build_event(:provider_event, session_id, %{"value" => inspect(other)}, other)]}
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

  defp stringify_keys(%{__struct__: _} = struct) do
    struct |> Map.from_struct() |> stringify_keys()
  end

  defp stringify_keys(map) when is_map(map) do
    map
    |> Enum.map(fn {k, v} -> {to_string(k), stringify_keys(v)} end)
    |> Map.new()
  end

  defp stringify_keys(list) when is_list(list), do: Enum.map(list, &stringify_keys/1)
  defp stringify_keys(value), do: value

  defp maybe_usage_event(%GeminiCliSdk.Types.Stats{} = stats, session_id, raw) do
    UsageEvent.build(:gemini, session_id || "unknown",
      input_tokens: stats.input_tokens || 0,
      output_tokens: stats.output_tokens || 0,
      total_tokens: stats.total_tokens || 0,
      duration_ms: stats.duration_ms,
      raw: raw
    )
  end

  defp maybe_usage_event(%{} = stats, session_id, raw) do
    input = stats["input_tokens"] || stats[:input_tokens] || 0
    output = stats["output_tokens"] || stats[:output_tokens] || 0
    total = stats["total_tokens"] || stats[:total_tokens] || input + output
    duration_ms = stats["duration_ms"] || stats[:duration_ms]

    if input > 0 or output > 0 do
      UsageEvent.build(:gemini, session_id || "unknown",
        input_tokens: input,
        output_tokens: output,
        total_tokens: total,
        duration_ms: duration_ms,
        raw: raw
      )
    else
      nil
    end
  end

  defp maybe_usage_event(_, _, _), do: nil
end
