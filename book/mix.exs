defmodule FastbookElixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :fastbook_elixir,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:req, "~> 0.5"},
      {:nx, "~> 0.11", optional: true},
      {:kino, "~> 0.19", optional: true}
    ]
  end
end
