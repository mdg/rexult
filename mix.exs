defmodule Rexult.MixProject do
  use Mix.Project

  def project do
    [
      app: :rexult,
      version: "0.1.1",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: [
        maintainers: ["Matthew Graham"],
        description: "An Elixir implementation of the result module from Rust",
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/mdg/rexult"},
      ],
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.4", only: :dev, runtime: false},
      {:ex_doc, "~> 0.32", only: :dev, runtime: false},
      {:freedom_formatter, "~> 2.1", only: [:dev, :test], runtime: false},
    ]
  end
end
