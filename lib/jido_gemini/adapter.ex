defmodule Jido.Gemini.Adapter do
  @moduledoc """
  `Jido.Harness.Adapter` implementation for Gemini CLI.
  """

  @behaviour Jido.Harness.Adapter

  alias GeminiCliSdk.Options
  alias Jido.Harness.{Capabilities, Event, RunRequest, RuntimeContract}
  alias Jido.Gemini.Mapper

  @option_keys [
    :model,
    :yolo,
    :approval_mode,
    :sandbox,
    :resume,
    :extensions,
    :include_directories,
    :allowed_tools,
    :allowed_mcp_server_names,
    :debug,
    :output_format,
    :cwd,
    :env,
    :settings,
    :system_prompt,
    :timeout_ms
  ]

  @impl true
  @spec id() :: atom()
  def id, do: :gemini

  @impl true
  @spec capabilities() :: map()
  def capabilities do
    %Capabilities{
      streaming?: true,
      tool_calls?: true,
      tool_results?: true,
      thinking?: false,
      cancellation?: false
    }
  end

  @impl true
  @spec run(RunRequest.t(), keyword()) :: {:ok, Enumerable.t()} | {:error, term()}
  def run(%RunRequest{} = request, opts \\ []) when is_list(opts) do
    with {:ok, options} <- build_options(request, opts) do
      stream =
        sdk_module()
        |> apply(:execute, [request.prompt, options])
        |> Stream.flat_map(fn event ->
          case mapper_module().map_event(event) do
            {:ok, events} when is_list(events) ->
              events

            {:error, reason} ->
              [mapper_error_event(reason)]
          end
        end)

      {:ok, stream}
    else
      {:error, _} = error ->
        error
    end
  rescue
    e in [ArgumentError] ->
      {:error, {:gemini_invalid_request, Exception.message(e)}}
  end

  @impl true
  @spec runtime_contract() :: RuntimeContract.t()
  def runtime_contract do
    RuntimeContract.new!(%{
      provider: :gemini,
      host_env_required_any: [
        "GEMINI_API_KEY",
        "GOOGLE_API_KEY",
        "GOOGLE_GENAI_USE_VERTEXAI",
        "GOOGLE_GENAI_USE_GCA"
      ],
      host_env_required_all: [],
      sprite_env_forward: [
        "GEMINI_API_KEY",
        "GOOGLE_API_KEY",
        "GOOGLE_GENAI_USE_VERTEXAI",
        "GOOGLE_GENAI_USE_GCA",
        "GOOGLE_CLOUD_PROJECT",
        "GOOGLE_CLOUD_LOCATION",
        "GH_TOKEN",
        "GITHUB_TOKEN"
      ],
      sprite_env_injected: %{
        "GH_PROMPT_DISABLED" => "1",
        "GIT_TERMINAL_PROMPT" => "0"
      },
      runtime_tools_required: ["gemini"],
      compatibility_probes: [
        %{
          "name" => "gemini_help_stream_json",
          "command" => "gemini --help",
          "expect_all" => ["--output-format", "stream-json"]
        }
      ],
      install_steps: [
        %{
          "tool" => "gemini",
          "when_missing" => true,
          "command" =>
            "if command -v npm >/dev/null 2>&1; then npm install -g @google/gemini-cli; else echo 'npm not available'; exit 1; fi"
        }
      ],
      auth_bootstrap_steps: [],
      triage_command_template:
        "if command -v timeout >/dev/null 2>&1; then timeout 120 gemini --output-format stream-json \"{{prompt}}\"; else gemini --output-format stream-json \"{{prompt}}\"; fi",
      coding_command_template:
        "if command -v timeout >/dev/null 2>&1; then timeout 180 gemini --output-format stream-json --approval-mode yolo \"{{prompt}}\"; else gemini --output-format stream-json --approval-mode yolo \"{{prompt}}\"; fi",
      success_markers: [
        %{"type" => "result", "status" => "success"}
      ]
    })
  end

  defp build_options(%RunRequest{} = request, opts) do
    metadata =
      request.metadata
      |> Map.get("gemini", Map.get(request.metadata, :gemini, %{}))
      |> normalize_map_keys()

    request_attrs =
      %{
        model: request.model,
        cwd: request.cwd,
        timeout_ms: request.timeout_ms,
        system_prompt: request.system_prompt,
        allowed_tools: request.allowed_tools
      }
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Enum.into(%{})

    runtime_attrs =
      opts
      |> Keyword.take(@option_keys)
      |> Enum.into(%{})

    attrs =
      request_attrs
      |> Map.merge(metadata)
      |> Map.merge(runtime_attrs)
      |> Map.put_new(:output_format, "stream-json")

    {:ok, struct(Options, attrs)}
  rescue
    e in [KeyError, ArgumentError] ->
      {:error, {:gemini_option_error, Exception.message(e)}}
  end

  defp normalize_map_keys(map) when is_map(map) do
    Enum.reduce(map, %{}, fn
      {key, value}, acc when is_atom(key) ->
        if key in @option_keys, do: Map.put(acc, key, value), else: acc

      {key, value}, acc when is_binary(key) ->
        atom =
          @option_keys
          |> Enum.find(fn item -> Atom.to_string(item) == key end)

        if atom, do: Map.put(acc, atom, value), else: acc

      _, acc ->
        acc
    end)
  end

  defp normalize_map_keys(_), do: %{}

  defp mapper_error_event(reason) do
    Event.new!(%{
      type: :session_failed,
      provider: :gemini,
      session_id: nil,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      payload: %{"error" => inspect(reason)},
      raw: reason
    })
  end

  defp mapper_module do
    Application.get_env(:jido_gemini, :mapper_module, Mapper)
  end

  defp sdk_module do
    Application.get_env(:jido_gemini, :sdk_module, GeminiCliSdk)
  end
end
