if Code.ensure_loaded?(OpentelemetryEcto) do
  defmodule Uplink.Monitors.OtelEcto do
    use Uplink.Monitor

    @impl true
    def init(opts) do
      prefix = Keyword.fetch!(opts, :repo_prefix)
      OpentelemetryEcto.setup(prefix)
    end
  end
end
