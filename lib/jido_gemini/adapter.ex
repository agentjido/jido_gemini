defmodule JidoGemini.Adapter do
  @moduledoc "JidoHarness.Adapter implementation for Google Gemini CLI."
  @behaviour JidoHarness.Adapter

  @impl true
  def id, do: :gemini

  @impl true
  def capabilities do
    %{
      streaming?: true,
      tool_calls?: true,
      tool_results?: true,
      thinking?: true,
      resume?: false,
      usage?: false,
      file_changes?: false,
      cancellation?: false
    }
  end

  @impl true
  def run(_request, _opts \\ []) do
    {:error, "not yet implemented"}
  end
end
