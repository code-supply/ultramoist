defmodule Ultramoist.MixProject do
  use Mix.Project

  def project do
    [
      app: :ultramoist,
      version: "0.1.0",
      elixir: "~> 1.20",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto, :public_key],
      mod: {Ultramoist.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:req, "~> 0.5"},
      {:plug, "~> 1.0", only: :test},
      {:mint_web_socket, "~> 1.0"}
    ]
  end
end
