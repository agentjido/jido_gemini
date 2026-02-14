defmodule JidoGemini do
  @moduledoc "Google Gemini CLI adapter for JidoHarness."

  @doc """
  Runs a prompt through the Gemini CLI adapter.

  Delegates to `JidoGemini.Adapter.run/2`.
  """
  def run(prompt, opts \\ []) do
    JidoGemini.Adapter.run(prompt, opts)
  end
end
