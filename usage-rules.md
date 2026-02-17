# JidoGemini Usage Rules for AI/LLM Development

## Context

JidoGemini is a thin adapter wrapping the Gemini CLI SDK to implement the Jido.Harness.Adapter behaviour.

## Key Concepts

### Adapter Pattern
- `JidoGemini.Adapter` implements `Jido.Harness.Adapter` behaviour
- `JidoGemini.Mapper` translates Gemini SDK events to normalized `Jido.Harness.Event` structs
- Keep the adapter thin — delegate to `gemini_cli_sdk` for heavy lifting

### Error Handling
- All errors use `Splode` error composition (when implemented)
- Validation errors use `JidoGemini.Error.InvalidInputError`
- Execution errors use `JidoGemini.Error.ExecutionFailureError`

### Schema Validation
- Core structs use Zoi schemas
- Use `new/1` and `new!/1` for struct construction with validation
- Validation logic stays in schemas, not scattered in functions

## Development Guidelines

### Adding Modules
1. Create under `lib/jido_gemini/`
2. Add `@moduledoc` with clear description
3. Define Zoi schema for any structs
4. Document all public functions with `@doc` and `@spec`
5. Create tests in `test/jido_gemini/`

### Testing
```bash
mix test --cover        # Run tests with coverage
mix quality             # Full quality checks
```

### Common Commands
```bash
mix setup               # Setup environment
mix test                # Run tests
mix quality             # Lint, format, dialyzer, doctor
mix docs                # Generate documentation
mix doctor --raise      # Check doc coverage
```

## Git Workflow

Use conventional commits:
```bash
git commit -m "feat(mapper): add event translation for X"
git commit -m "fix(adapter): handle error case in Y"
git commit -m "docs: clarify usage of Z"
```

Valid commit types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `ci`

## Code Standards

- Line length: 120 characters
- No `IO.puts` — use `Logger` for output
- All public functions need `@doc` and `@spec`
- No `jido_dep/4` helper functions
- Tests must have >90% coverage

## Integration Points

### Gemini CLI SDK
- Wraps `GeminiCliSdk.execute/2` for running prompts
- Maps SDK response events to `Jido.Harness.Event` structs

### Jido.Harness
- Implements `Jido.Harness.Adapter` behaviour
- Events comply with `Jido.Harness.Event` schema

## Questions?

- Review `AGENTS.md` for project-specific instructions
- Check `GENERIC_PACKAGE_QA.md` for ecosystem standards
- Look at `jido_amp` or `jido_claude` for adapter patterns
