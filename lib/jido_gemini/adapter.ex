defmodule JidoGemini.Adapter do
  @moduledoc """
  JidoHarness.Adapter implementation for Google Gemini CLI.

  This module adapts the Gemini CLI SDK to implement the JidoHarness.Adapter behaviour,
  translating Gemini events into normalized JidoHarness.Event structs.
  """

  require Logger

  @doc """
  Runs a prompt through the Gemini CLI SDK and translates events.

  ## Parameters

    * `prompt` - The prompt string
    * `opts` - Keyword list of options

  ## Returns

    * `{:ok, stream}` - A stream of JidoHarness.Event structs
    * `{:error, reason}` - Error tuple on failure
  """
  @spec run(String.t(), keyword()) :: {:ok, Enumerable.t()} | {:error, term()}
  def run(prompt, opts \\ []) when is_binary(prompt) and is_list(opts) do
    # TODO: Implement Gemini SDK integration
    # 1. Call GeminiCliSdk.execute/2 with prompt and opts
    # 2. Map returned events via JidoGemini.Mapper.map_event/1
    # 3. Return stream of normalized events

    Logger.debug("JidoGemini.Adapter.run/2 called", prompt: prompt, opts: opts)
    {:ok, Stream.flat_map([], & &1)}
  end
end
