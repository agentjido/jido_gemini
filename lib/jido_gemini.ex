defmodule JidoGemini do
  @moduledoc """
  Google Gemini CLI adapter for JidoHarness.

  Provides a thin wrapper around the Gemini CLI SDK, translating its events
  into normalized JidoHarness.Event structs.

  ## Usage

      {:ok, events} = JidoGemini.run("your prompt")
      Stream.each(events, &handle_event/1)
  """

  @doc """
  Runs a prompt through the Gemini CLI adapter.

  Delegates to `JidoGemini.Adapter.run/2` to handle the actual execution
  and event translation from the Gemini SDK to JidoHarness events.

  ## Parameters

    * `prompt` - The prompt string to send to Gemini
    * `opts` - Keyword list of options (default: `[]`)

  ## Returns

    * `{:ok, stream}` - A stream of normalized JidoHarness.Event structs
    * `{:error, reason}` - An error tuple on failure
  """
  @spec run(String.t(), keyword()) :: {:ok, Enumerable.t()} | {:error, term()}
  def run(prompt, opts \\ []) do
    JidoGemini.Adapter.run(prompt, opts)
  end
end
