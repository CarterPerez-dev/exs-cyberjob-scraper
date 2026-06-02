# © AngelaMos | 2026
# mix.exs

defmodule CertScout.MixProject do
  use Mix.Project

  def project do
    [
      app: :certscout,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      escript: escript(),
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger, :inets, :ssl]]
  end

  defp escript do
    [main_module: CertScout.CLI, name: "certscout"]
  end

  defp deps do
    [
      {:req, "~> 0.5"},
      {:floki, "~> 0.36"},
      {:nimble_csv, "~> 1.2"},
      {:styler, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end
end
