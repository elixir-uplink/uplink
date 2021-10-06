defmodule OrgUplink.MixProject do
  use Mix.Project

  def project do
    [
      app: :org_uplink,
      version: "0.1.0",
      elixir: "~> 1.10",
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
      {:uplink, path: "../../../uplink"},
      {:telemetry_metrics_prometheus, "~> 1.1"},
      {:telemetry_metrics_prometheus_core, "~> 1.0"},
      {:opentelemetry_phoenix, "~> 1.0-beta"},
      {:jason, "~> 1.2"},
      {:recon, "~> 2.5"}
    ]
  end
end
