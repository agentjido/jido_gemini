defmodule Jido.Gemini.Compatibility do
  @moduledoc """
  Runtime compatibility checks for local Gemini CLI features.
  """

  @command_timeout 5_000
  @required_tokens ["--output-format", "stream-json"]

  @doc "Returns compatibility metadata for the current Gemini CLI."
  @spec status(keyword()) :: {:ok, map()} | {:error, Exception.t()}
  def status(opts \\ []) when is_list(opts) do
    with {:ok, spec} <- resolve_cli(opts),
         {:ok, help_output} <- read_help(spec.program),
         :ok <- ensure_stream_json_support(help_output) do
      {:ok,
       %{
         program: spec.program,
         version: read_version(spec.program),
         required_tokens: @required_tokens
       }}
    end
  end

  @doc "Returns `:ok` if compatible, otherwise a structured error."
  @spec check(keyword()) :: :ok | {:error, Exception.t()}
  def check(opts \\ []) when is_list(opts) do
    case status(opts) do
      {:ok, _metadata} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  @doc "Boolean predicate for compatibility checks."
  @spec compatible?(keyword()) :: boolean()
  def compatible?(opts \\ []) when is_list(opts) do
    match?({:ok, _}, status(opts))
  end

  @doc "Raises when current Gemini CLI is incompatible with stream-json mode."
  @spec assert_compatible!(keyword()) :: :ok | no_return()
  def assert_compatible!(opts \\ []) when is_list(opts) do
    case check(opts) do
      :ok -> :ok
      {:error, error} -> raise error
    end
  end

  @doc "Returns true when a Gemini CLI binary can be resolved."
  @spec cli_installed?(keyword()) :: boolean()
  def cli_installed?(opts \\ []) when is_list(opts) do
    match?({:ok, _}, resolve_cli(opts))
  end

  @doc false
  @spec cli_module() :: module()
  def cli_module do
    Application.get_env(:jido_gemini, :gemini_cli_module, Jido.Gemini.CLI)
  end

  @doc false
  @spec command_module() :: module()
  def command_module do
    Application.get_env(:jido_gemini, :gemini_command_module, Jido.Gemini.SystemCommand)
  end

  defp resolve_cli(opts) do
    case cli_module().resolve(opts) do
      {:ok, spec} ->
        {:ok, spec}

      {:error, reason} ->
        {:error,
         RuntimeError.exception(
           "Gemini CLI is not available. Install Gemini and run `mix gemini.install`. (#{inspect(reason)})"
         )}
    end
  end

  defp read_help(program) do
    case command_module().run(program, ["--help"], timeout: @command_timeout) do
      {:ok, output} ->
        {:ok, output}

      {:error, reason} ->
        {:error,
         RuntimeError.exception("Unable to read Gemini CLI help output for compatibility checks. (#{inspect(reason)})")}
    end
  end

  defp ensure_stream_json_support(help_output) do
    missing = Enum.reject(@required_tokens, &String.contains?(help_output, &1))

    case missing do
      [] ->
        :ok

      _ ->
        {:error,
         RuntimeError.exception(
           "Installed Gemini CLI is incompatible with stream-json mode. Missing tokens in `gemini --help`: #{Enum.join(missing, ", ")}."
         )}
    end
  end

  defp read_version(program) do
    case command_module().run(program, ["--version"], timeout: @command_timeout) do
      {:ok, version} -> String.trim(version)
      {:error, _reason} -> "unknown"
    end
  end
end
