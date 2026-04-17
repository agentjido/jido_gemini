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
