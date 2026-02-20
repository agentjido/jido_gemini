defmodule Mix.Tasks.Gemini.Smoke do
  @moduledoc """
  Execute a minimal Gemini prompt for smoke validation.

      mix gemini.smoke "Say hello"
      mix gemini.smoke "Summarize this repo" --cwd /path --timeout 30000
  """

  @shortdoc "Run a minimal Gemini smoke prompt"

  use Mix.Task
  alias Jido.Gemini.MixTaskHelpers

  @switches [cwd: :string, timeout: :integer]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    {opts, positional, invalid} = OptionParser.parse(args, strict: @switches)
    MixTaskHelpers.validate_options!(invalid)

    prompt =
      case positional do
        [value] -> value
        _ -> Mix.raise("expected exactly one PROMPT argument")
      end

    run_opts =
      []
      |> maybe_put(:cwd, opts[:cwd])
      |> maybe_put(:timeout_ms, opts[:timeout])

    Mix.shell().info(["Running Gemini smoke prompt..."])

    case gemini_module().run(prompt, run_opts) do
      {:ok, stream} ->
        count = stream |> Enum.take(10_000) |> length()
        Mix.shell().info("Smoke run completed with #{count} normalized events.")

      {:error, reason} ->
        Mix.raise("Gemini smoke run failed: #{format_error(reason)}")
    end
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)

  defp format_error(%{message: message}) when is_binary(message), do: message
  defp format_error(reason), do: inspect(reason)

  defp gemini_module do
    Application.get_env(:jido_gemini, :gemini_public_module, Jido.Gemini)
  end
end
