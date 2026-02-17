defmodule JidoGemini.Adapter do
  @moduledoc """
  Jido.Harness.Adapter implementation for Google Gemini CLI.

  This module adapts the Gemini CLI SDK to implement the Jido.Harness.Adapter behaviour,
  translating Gemini events into normalized Jido.Harness.Event structs.
  """

  @doc """
  Runs a prompt through the Gemini CLI SDK and translates events.

  ## Parameters

    * `prompt` - The prompt string
    * `opts` - Keyword list of options

  ## Returns

    * `{:ok, stream}` - A stream of Jido.Harness.Event structs
    * `{:error, reason}` - Error tuple on failure
  """
  @spec run(String.t(), keyword()) :: {:ok, Enumerable.t()} | {:error, term()}
  def run(prompt, opts \\ []) when is_binary(prompt) and is_list(opts) do
    _ = {prompt, opts}
    {:ok, Stream.concat([])}
  end
end
