defmodule Vera.MixProject do
  use Mix.Project

  def project do
    [
      app: :vera,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases(),
      env: []
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp releases do
    [
      vera: [
        include_erts: true,
        strip_beams: false,
        include_executables_for: [:unix],
        applications: [runtime_tools: :permanent],
        cookie: "augury-kinship-swain-circus",
        steps: [:assemble, :tar]
      ]
    ]
  end
end
