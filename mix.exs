defmodule Iona.Mixfile do
  use Mix.Project

  def project do
    [
      app: :iona,
      version: "1.0.0-alpha.6",
      elixir: "~> 1.5.1 or ~> 1.6",
      source_url: "https://github.com/jshmrtn/iona",
      build_embeddedalc: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
      dialyzer: [ignore_warnings: ".dialyzer_ignore.exs"]
    ]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [
      extra_applications: [:logger, :eex],
      env: default_env()
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:briefly, "~> 0.3"},
      {:dialyxir, "~> 1.1", only: [:dev], runtime: false},
      {:ex_doc, ">= 0.0.0", only: [:dev]},
      {:credo, "~> 1.5", only: [:dev], runtime: false}
    ]
  end

  defp package do
    [
      description: "Document generation using LaTeX",
      files: ["lib", "mix.exs", "README*", "LICENSE"],
      maintainers: ["Bruce Williams", "Jonatan Männchen"],
      licenses: ["Apache 2"],
      links: %{github: "https://github.com/jshmrtn/iona"}
    ]
  end

  defp default_env do
    [preprocess: [], processors: [pdf: "pdflatex", dvi: "latex"], helpers: [Iona.Template.Helper]]
  end
end
