# Getting Started with JidoGemini

JidoGemini is an adapter that wraps the Gemini CLI SDK to implement the JidoHarness.Adapter behaviour.

## Installation

Add `jido_gemini` to your `mix.exs` dependencies:

```elixir
defp deps do
  [
    {:jido_gemini, "~> 0.1"}
  ]
end
```

Then run:

```bash
mix deps.get
```

## Basic Usage

```elixir
# Run a prompt through Gemini
{:ok, events} = JidoGemini.run("your prompt here")

# Events will be a stream of normalized JidoHarness.Event structs
```

## Adapter Implementation

JidoGemini.Adapter implements the `JidoHarness.Adapter` behaviour:

```elixir
defmodule JidoGemini.Adapter do
  @behaviour JidoHarness.Adapter

  def run(prompt, opts) do
    # Maps Gemini SDK events to JidoHarness.Event structs
  end
end
```

## Next Steps

- Check `README.md` for more documentation
- Review `lib/jido_gemini/` for the adapter implementation
- See `test/` for usage examples
