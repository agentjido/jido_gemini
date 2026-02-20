defmodule Mix.Tasks.Gemini.Install do
  @moduledoc """
  Check for the Gemini CLI and provide installation instructions.

      mix gemini.install
  """

  @shortdoc "Check Gemini CLI installation and provide setup instructions"

  use Mix.Task
  alias Jido.Gemini.CLI

  @switches [path: :string]

  @impl true
  def run(args) do
    {opts, _positional, invalid} = OptionParser.parse(args, strict: @switches)
    Jido.Gemini.MixTaskHelpers.validate_options!(invalid)

    resolve_opts =
      if is_binary(opts[:path]) and opts[:path] != "" do
        [gemini_cli_path: opts[:path]]
      else
        []
      end

    case cli_module().resolve(resolve_opts) do
      {:ok, spec} ->
        Mix.shell().info(["Gemini CLI found: ", :green, spec.program, :reset])

      {:error, _} ->
        Mix.shell().info([
          :yellow,
          "Gemini CLI not found.",
          :reset,
          "\n\n",
          "Install the Gemini CLI using one of these methods:\n\n",
          "  npm install -g @google/gemini-cli\n\n",
          "After installation, run this task again to verify:\n\n",
          "  mix gemini.install\n"
        ])
    end
  end

  defp cli_module do
    Application.get_env(:jido_gemini, :gemini_cli_module, CLI)
  end
end
