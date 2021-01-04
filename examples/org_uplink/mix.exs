defmodule OrgUplink.MixProject do
  use Mix.Project

  def project do
    [
      app: :org_uplink,
      version: "0.1.0",
      elixir: "~> 1.11",
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
      {:telemetry_metrics_prometheus, "~> 0.6"},
      {:telemetry_metrics_prometheus_core, "~> 0.4"},
      {:opentelemetry_phoenix, "~> 0.2"},
      {:jason, "~> 1.2"},
      {:recon, "~> 2.5"}
    ]
  end
end
