defmodule Mix.Tasks.GeminiTasksTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Jido.Gemini.Test.{StubCLI, StubPublicGemini}
  alias Mix.Tasks.Gemini.{Compat, Install, Smoke}

  setup do
    old_cli_module = Application.get_env(:jido_gemini, :gemini_cli_module)
    old_compat_module = Application.get_env(:jido_gemini, :gemini_compat_module)
    old_public_module = Application.get_env(:jido_gemini, :gemini_public_module)
    old_stub_cli_resolve = Application.get_env(:jido_gemini, :stub_cli_resolve)
    old_stub_compat_status = Application.get_env(:jido_gemini, :stub_compat_status)
    old_stub_public_gemini_run = Application.get_env(:jido_gemini, :stub_public_gemini_run)

    Application.put_env(:jido_gemini, :gemini_cli_module, StubCLI)
    Application.put_env(:jido_gemini, :gemini_compat_module, __MODULE__.StubCompatibility)
    Application.put_env(:jido_gemini, :gemini_public_module, StubPublicGemini)

    Application.put_env(:jido_gemini, :stub_cli_resolve, fn _opts -> {:ok, %{program: "/tmp/gemini"}} end)

    Application.put_env(:jido_gemini, :stub_compat_status, fn _opts ->
      {:ok, %{program: "/tmp/gemini", version: "1.2.3", required_tokens: ["--output-format", "stream-json"]}}
    end)

    Application.put_env(:jido_gemini, :stub_public_gemini_run, fn prompt, opts ->
      send(self(), {:smoke_run, prompt, opts})
      {:ok, [%{type: :session_started}]}
    end)

    on_exit(fn ->
      restore_env(:jido_gemini, :gemini_cli_module, old_cli_module)
      restore_env(:jido_gemini, :gemini_compat_module, old_compat_module)
      restore_env(:jido_gemini, :gemini_public_module, old_public_module)
      restore_env(:jido_gemini, :stub_cli_resolve, old_stub_cli_resolve)
      restore_env(:jido_gemini, :stub_compat_status, old_stub_compat_status)
      restore_env(:jido_gemini, :stub_public_gemini_run, old_stub_public_gemini_run)
    end)

    :ok
  end

  defmodule StubCompatibility do
    def status(opts \\ []) do
      Application.get_env(:jido_gemini, :stub_compat_status, fn _opts ->
        {:ok, %{program: "/tmp/gemini", version: "1.2.3", required_tokens: ["--output-format", "stream-json"]}}
      end).(opts)
    end
  end

  test "mix gemini.install prints found message" do
    Mix.Task.reenable("gemini.install")

    output =
      capture_io(fn ->
        Install.run([])
      end)

    assert output =~ "Gemini CLI found"
    assert output =~ "/tmp/gemini"
  end

  test "mix gemini.install prints install instructions when missing" do
    Application.put_env(:jido_gemini, :stub_cli_resolve, fn _opts -> {:error, :enoent} end)

    Mix.Task.reenable("gemini.install")

    output =
      capture_io(fn ->
        Install.run([])
      end)

    assert output =~ "Gemini CLI not found"
    assert output =~ "mix gemini.install"
  end

  test "mix gemini.install validates unknown options" do
    Mix.Task.reenable("gemini.install")

    assert_raise Mix.Error, ~r/invalid options: --bad/, fn ->
      capture_io(fn ->
        Install.run(["--bad"])
      end)
    end
  end

  test "mix gemini.compat prints success" do
    Mix.Task.reenable("gemini.compat")

    output =
      capture_io(fn ->
        Compat.run([])
      end)

    assert output =~ "Gemini compatibility check passed"
    assert output =~ "Required tokens"
  end

  test "mix gemini.compat raises when status returns error" do
    Application.put_env(:jido_gemini, :stub_compat_status, fn _opts ->
      {:error, RuntimeError.exception("bad compat")}
    end)

    Mix.Task.reenable("gemini.compat")

    assert_raise Mix.Error, ~r/Gemini compatibility check failed/, fn ->
      capture_io(fn ->
        Compat.run([])
      end)
    end
  end

  test "mix gemini.compat validates unknown options" do
    Mix.Task.reenable("gemini.compat")

    assert_raise Mix.Error, ~r/invalid options: --bad/, fn ->
      capture_io(fn ->
        Compat.run(["--bad"])
      end)
    end
  end

  test "mix gemini.smoke executes smoke run" do
    Mix.Task.reenable("gemini.smoke")

    output =
      capture_io(fn ->
        Smoke.run(["Say hello", "--cwd", "/tmp/project", "--timeout", "3000"])
      end)

    assert_receive {:smoke_run, "Say hello", opts}
    assert opts[:cwd] == "/tmp/project"
    assert opts[:timeout_ms] == 3000
    assert output =~ "Smoke run completed"
  end

  test "mix gemini.smoke validates prompt presence" do
    Mix.Task.reenable("gemini.smoke")

    assert_raise Mix.Error, ~r/expected exactly one PROMPT/, fn ->
      capture_io(fn ->
        Smoke.run([])
      end)
    end
  end

  test "mix gemini.smoke validates unknown options" do
    Mix.Task.reenable("gemini.smoke")

    assert_raise Mix.Error, ~r/invalid options: --bad/, fn ->
      capture_io(fn ->
        Smoke.run(["hello", "--bad"])
      end)
    end
  end

  test "mix gemini.smoke raises on run failure" do
    Application.put_env(:jido_gemini, :stub_public_gemini_run, fn _prompt, _opts ->
      {:error, %{message: "boom"}}
    end)

    Mix.Task.reenable("gemini.smoke")

    assert_raise Mix.Error, ~r/Gemini smoke run failed: boom/, fn ->
      capture_io(fn ->
        Smoke.run(["hi"])
      end)
    end
  end

  defp restore_env(app, key, nil), do: Application.delete_env(app, key)
  defp restore_env(app, key, value), do: Application.put_env(app, key, value)
end
