# JidoGemini

Google Gemini CLI adapter for [Jido.Harness](https://github.com/agentjido/jido_harness).

## Status

⚠️ **Early development** — API is subject to change.

## Installation

Add `jido_gemini` and `jido_harness` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:jido_harness, "~> 0.1"},
    {:jido_gemini, "~> 0.1"}
  ]
end
```

## Usage

```elixir
JidoGemini.run("Hello, Gemini!")
```

## License

Apache-2.0 — see [LICENSE](LICENSE) for details.
