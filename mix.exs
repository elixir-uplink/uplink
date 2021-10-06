defmodule Uplink.MixProject do
  use Mix.Project

  @version "0.2.0"

  def project do
    [
      app: :uplink,
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      description: description(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp docs do
    [
      main: "Uplink",
      canonical: "http://hexdocs.pm/uplink",
      source_url: "https://github.com/elixir-uplink/uplink",
      source_ref: "v#{@version}",
      extras: [
        "README.md"
      ],
      deps: [
        telemetry: "https://hexdocs.pm/telemetry",
        telemetry_poller: "https://hexdocs.pm/telemetry_poller"
      ]
    ]
  end

  defp description do
    """
    A simple abstraction for standardized observability with telemetry and more.
    """
  end

  defp package do
    [
      maintainers: ["Bryan Naegele"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/elixir-uplink/uplink"
      }
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 1.1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.25", only: [:dev, :docs]},
      {:telemetry, "~> 1.0"},
      {:telemetry_metrics, "~> 0.6.1"},
      {:telemetry_poller, "~> 1.0"},
      {:telemetry_registry, "~> 0.3"}
    ]
  end
end
