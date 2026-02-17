defmodule JidoGemini.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/agentjido/jido_gemini"
  @description "Google Gemini CLI adapter for Jido.Harness"

  def project do
    [
      app: :jido_gemini,
      version: @version,
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      # Documentation
      name: "JidoGemini",
      description: @description,
      source_url: @source_url,
      homepage_url: @source_url,
      docs: [
        main: "JidoGemini",
        extras: ["README.md", "CHANGELOG.md", "CONTRIBUTING.md", "guides/getting-started.md"],
        formatters: ["html"]
      ],
      test_coverage: [
        tool: ExCoveralls,
        summary: [threshold: 90]
      ],
      # Hex packaging
      package: [
        name: :jido_gemini,
        description: @description,
        files: [
          ".formatter.exs",
          "CHANGELOG.md",
          "CONTRIBUTING.md",
          "LICENSE",
          "README.md",
          "usage-rules.md",
          "config",
          "guides",
          "lib",
          "mix.exs"
        ],
        licenses: ["Apache-2.0"],
        links: %{"GitHub" => @source_url}
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.github": :test,
        "coveralls.html": :test
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Core ecosystem
      {:zoi, "~> 0.16"},
      {:splode, "~> 0.3"},
      {:jido_harness, path: "../jido_harness"},
      # {:gemini_cli_sdk, "~> 0.1"},
      {:jason, "~> 1.4"},

      # Dev/Test
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:doctor, "~> 0.21", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18", only: [:dev, :test]},
      {:git_hooks, "~> 0.8", only: [:dev, :test], runtime: false},
      {:git_ops, "~> 2.9", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "git_hooks.install"],
      q: ["quality"],
      quality: [
        "format --check-formatted",
        "compile --warnings-as-errors",
        "credo --min-priority higher",
        "dialyzer",
        "doctor --raise"
      ],
      test: ["test --cover --color"],
      "test.watch": ["watch -c \"mix test\""]
    ]
  end
end
