defmodule Jido.Gemini do
  @moduledoc """
  Google Gemini CLI adapter for Jido.Harness.

  Provides a thin wrapper around the Gemini CLI SDK, translating its events
  into normalized Jido.Harness.Event structs.

  ## Usage

      {:ok, events} = Jido.Gemini.run("your prompt")
      Stream.each(events, &handle_event/1)
  """

  @doc """
  Runs a prompt through the Gemini CLI adapter.

  Delegates to `Jido.Gemini.Adapter.run/2` to handle the actual execution
  and event translation from the Gemini SDK to Jido.Harness events.

  ## Parameters

    * `prompt` - The prompt string to send to Gemini
    * `opts` - Keyword list of options (default: `[]`)

  ## Returns

    * `{:ok, stream}` - A stream of normalized Jido.Harness.Event structs
    * `{:error, reason}` - An error tuple on failure
  """
  @spec run(String.t(), keyword()) :: {:ok, Enumerable.t()} | {:error, term()}
  def run(prompt, opts \\ []) when is_binary(prompt) and is_list(opts) do
    request_opts =
      opts
      |> Keyword.take([:cwd, :model, :max_turns, :timeout_ms, :system_prompt, :allowed_tools, :attachments, :metadata])

    adapter_opts =
      opts
      |> Keyword.drop([:cwd, :model, :max_turns, :timeout_ms, :system_prompt, :allowed_tools, :attachments, :metadata])

    with {:ok, request} <- Jido.Harness.RunRequest.new(Map.new([{:prompt, prompt} | request_opts])) do
      Jido.Gemini.Adapter.run(request, adapter_opts)
    end
  end
end
