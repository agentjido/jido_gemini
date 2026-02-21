defmodule Jido.Gemini.CLI do
  @moduledoc false

  @type cli_spec :: %{required(:program) => String.t()}
  @type resolve_opt :: {:gemini_cli_path, String.t()} | {:cli_path, String.t()}

  @doc """
  Returns a configured Gemini CLI path from opts or application config.
  """
  @spec configured_path([resolve_opt()]) :: String.t() | nil
  def configured_path(opts \\ []) when is_list(opts) do
    opts[:gemini_cli_path] ||
      opts[:cli_path] ||
      Application.get_env(:jido_gemini, :gemini_cli_path)
  end

  @doc """
  Resolves the Gemini CLI executable path from override config or system PATH.
  """
  @spec resolve([resolve_opt()]) :: {:ok, cli_spec()} | {:error, :enoent}
  def resolve(opts \\ []) when is_list(opts) do
    case configured_path(opts) do
      path when is_binary(path) and path != "" ->
        if File.regular?(path) do
          {:ok, %{program: path}}
        else
          {:error, :enoent}
        end

      _ ->
        case System.find_executable("gemini") do
          nil -> {:error, :enoent}
          path -> {:ok, %{program: path}}
        end
    end
  end
end
