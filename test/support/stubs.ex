defmodule Jido.Gemini.Test.StubCLI do
  @moduledoc false

  def resolve(opts \\ []) do
    Application.get_env(:jido_gemini, :stub_cli_resolve, fn _opts -> {:ok, %{program: "/tmp/gemini"}} end).(opts)
  end
end

defmodule Jido.Gemini.Test.StubCommand do
  @moduledoc false

  def run(program, args, opts \\ []) do
    Application.get_env(:jido_gemini, :stub_command_run, fn _program, _args, _opts -> {:ok, "ok"} end).(
      program,
      args,
      opts
    )
  end
end

defmodule Jido.Gemini.Test.StubPublicGemini do
  @moduledoc false

  def run(prompt, opts) do
    Application.get_env(:jido_gemini, :stub_public_gemini_run, fn _prompt, _opts -> {:ok, []} end).(prompt, opts)
  end
end
