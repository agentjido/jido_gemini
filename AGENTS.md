# AGENTS.md — JidoGemini

## Overview

JidoGemini is a thin adapter that wraps the `gemini_cli_sdk` package to implement the `JidoHarness.Adapter` behaviour.

## Structure

- `lib/jido_gemini.ex` — Public API (`run/2`)
- `lib/jido_gemini/adapter.ex` — `JidoHarness.Adapter` implementation
- `lib/jido_gemini/mapper.ex` — Maps Gemini CLI SDK events to `JidoHarness.Event` structs

## Commands

- `mix test` — Run tests
- `mix quality` — Full quality checks (compile, format, credo, dialyzer, doctor)
- `mix format` — Format code

## Conventions

- Follow standard Elixir conventions
- Line length: 120 characters
- Use `Logger` for output, not `IO.puts`
