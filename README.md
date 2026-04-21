# Jido.Gemini

Google Gemini CLI adapter for [Jido.Harness](https://github.com/agentjido/jido_harness).

## Status

⚠️ **Early development** — API is subject to change.

## Installation

Add `jido_gemini` and `jido_harness` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:jido_harness, github: "agentjido/jido_harness", branch: "main", override: true},
    {:jido_gemini, github: "agentjido/jido_gemini", branch: "main"}
  ]
end
```

This repo is currently aligned as part of the GitHub-based harness package set rather than a Hex release line.

## Usage

```elixir
Jido.Gemini.run("Hello, Gemini!")
```

## Runtime Tooling

Use the built-in tasks to validate local CLI readiness:

```bash
mix gemini.install
mix gemini.compat
mix gemini.smoke "Say hello"
```

## License

Apache-2.0 — see [LICENSE](LICENSE) for details.

## Package Purpose

`jido_gemini` is the Gemini CLI adapter for `jido_harness`, providing normalized request/event handling and runtime compatibility checks.

## Testing Paths

- Unit/contract tests: `mix test`
- Full quality gate: `mix quality`
- Optional live checks: `mix gemini.install && mix gemini.compat`

## Live Integration Test

`jido_gemini` includes an opt-in live adapter test that runs the real Gemini CLI through the harness adapter path:

```bash
mix test --include integration test/jido_gemini/integration/adapter_live_integration_test.exs
```

The test auto-loads `.env` and is excluded from default `mix test` runs.

Environment knobs:

- `GEMINI_API_KEY` or `GOOGLE_API_KEY` for env-based auth
- `GOOGLE_GENAI_USE_VERTEXAI` or `GOOGLE_GENAI_USE_GCA` for Vertex/GCA auth flows
- `JIDO_GEMINI_LIVE_PROMPT` to override the default prompt
- `JIDO_GEMINI_LIVE_CWD` to override the working directory
- `JIDO_GEMINI_LIVE_MODEL` to force a specific model
- `JIDO_GEMINI_LIVE_TIMEOUT_MS` to extend the per-run timeout
- `JIDO_GEMINI_REQUIRE_SUCCESS=1` to fail unless the terminal event is successful
- `JIDO_GEMINI_CLI_PATH` to target a non-default Gemini CLI binary
