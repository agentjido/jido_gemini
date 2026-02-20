defmodule Jido.Gemini.CompatibilityTest do
  use ExUnit.Case, async: false

  alias Jido.Gemini.Compatibility
  alias Jido.Gemini.Test.{StubCLI, StubCommand}

  setup do
    old_cli_module = Application.get_env(:jido_gemini, :gemini_cli_module)
    old_command_module = Application.get_env(:jido_gemini, :gemini_command_module)
    old_cli_resolve = Application.get_env(:jido_gemini, :stub_cli_resolve)
    old_command_run = Application.get_env(:jido_gemini, :stub_command_run)

    Application.put_env(:jido_gemini, :gemini_cli_module, StubCLI)
    Application.put_env(:jido_gemini, :gemini_command_module, StubCommand)

    on_exit(fn ->
      restore_env(:jido_gemini, :gemini_cli_module, old_cli_module)
      restore_env(:jido_gemini, :gemini_command_module, old_command_module)
      restore_env(:jido_gemini, :stub_cli_resolve, old_cli_resolve)
      restore_env(:jido_gemini, :stub_command_run, old_command_run)
    end)

    :ok
  end

  test "returns error when CLI is missing" do
    Application.put_env(:jido_gemini, :stub_cli_resolve, fn _opts -> {:error, :enoent} end)

    assert {:error, %RuntimeError{}} = Compatibility.status()
    assert Compatibility.compatible?() == false
    assert {:error, %RuntimeError{}} = Compatibility.check()
    assert Compatibility.cli_installed?() == false
  end

  test "returns error when stream-json support is not present" do
    Application.put_env(:jido_gemini, :stub_cli_resolve, fn _opts -> {:ok, %{program: "/tmp/gemini"}} end)

    Application.put_env(:jido_gemini, :stub_command_run, fn
      _program, ["--help"], _opts -> {:ok, "Usage: gemini --output-format text"}
      _program, _args, _opts -> {:ok, "ok"}
    end)

    assert {:error, %RuntimeError{}} = Compatibility.status()
    assert Compatibility.compatible?() == false
  end

  test "returns ok when required tokens are present" do
    Application.put_env(:jido_gemini, :stub_cli_resolve, fn _opts -> {:ok, %{program: "/tmp/gemini"}} end)

    Application.put_env(:jido_gemini, :stub_command_run, fn
      _program, ["--help"], _opts -> {:ok, "gemini --output-format stream-json"}
      _program, ["--version"], _opts -> {:ok, "1.2.3"}
      _program, _args, _opts -> {:ok, "ok"}
    end)

    assert {:ok, status} = Compatibility.status()
    assert status.program == "/tmp/gemini"
    assert status.version == "1.2.3"
    assert Compatibility.compatible?() == true
    assert Compatibility.check() == :ok
    assert Compatibility.assert_compatible!() == :ok
    assert Compatibility.cli_installed?() == true
  end

  test "returns unknown version when version command fails" do
    Application.put_env(:jido_gemini, :stub_cli_resolve, fn _opts -> {:ok, %{program: "/tmp/gemini"}} end)

    Application.put_env(:jido_gemini, :stub_command_run, fn
      _program, ["--help"], _opts -> {:ok, "gemini --output-format stream-json"}
      _program, ["--version"], _opts -> {:error, :boom}
      _program, _args, _opts -> {:ok, "ok"}
    end)

    assert {:ok, status} = Compatibility.status()
    assert status.version == "unknown"
  end

  test "assert_compatible!/1 raises for incompatible runtime" do
    Application.put_env(:jido_gemini, :stub_cli_resolve, fn _opts -> {:error, :enoent} end)

    assert_raise RuntimeError, fn ->
      Compatibility.assert_compatible!()
    end
  end

  defp restore_env(app, key, nil), do: Application.delete_env(app, key)
  defp restore_env(app, key, value), do: Application.put_env(app, key, value)
end
