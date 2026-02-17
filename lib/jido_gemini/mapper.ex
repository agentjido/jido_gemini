defmodule JidoGemini.Mapper do
  @moduledoc """
  Maps Gemini CLI SDK events to Jido.Harness.Event structs.

  This module provides the translation layer between the Gemini CLI SDK's native
  event format and the normalized Jido.Harness.Event format.
  """

  @doc """
  Maps a Gemini SDK event to a Jido.Harness.Event struct.

  ## Parameters

    * `gemini_event` - An event from the Gemini CLI SDK

  ## Returns

    * `{:ok, event}` - A normalized Jido.Harness.Event struct
    * `{:error, reason}` - Error tuple on invalid event
  """
  @spec map_event(term()) :: {:ok, map()} | {:error, term()}
  def map_event(gemini_event) when is_map(gemini_event) do
    {:ok, gemini_event}
  end

  def map_event(_), do: {:error, :invalid_event}
end
