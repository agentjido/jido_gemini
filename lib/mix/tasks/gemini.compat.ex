defmodule Mix.Tasks.Gemini.Compat do
  @moduledoc """
  Validate whether the local Gemini CLI supports stream-json mode.

      mix gemini.compat
      mix gemini.compat --path /custom/gemini
  """

  @shortdoc "Validate Gemini CLI compatibility"

  use Mix.Task
  alias Jido.Gemini.MixTaskHelpers

  @switches [path: :string]

  @impl true
  def run(args) do
    {opts, _positional, invalid} = OptionParser.parse(args, strict: @switches)
    MixTaskHelpers.validate_options!(invalid)

    compat_opts =
      if is_binary(opts[:path]) and opts[:path] != "" do
        [gemini_cli_path: opts[:path]]
      else
        []
      end

    case compatibility_module().status(compat_opts) do
      {:ok, metadata} ->
        Mix.shell().info([
          :green,
          "Gemini compatibility check passed.",
          :reset,
          "\n",
          "CLI: ",
          metadata.program,
          "\n",
          "Version: ",
          metadata.version,
          "\n",
          "Required tokens: ",
          Enum.join(metadata.required_tokens, ", ")
        ])

      {:error, error} ->
        Mix.raise("""
        Gemini compatibility check failed.

        #{Exception.message(error)}
        """)
    end
  end

  defp compatibility_module do
    Application.get_env(:jido_gemini, :gemini_compat_module, Jido.Gemini.Compatibility)
  end
end
