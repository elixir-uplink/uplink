if Code.ensure_loaded?(OpentelemetryEcto) do
  defmodule Uplink.Monitors.OtelPhoenix do
    use Uplink.Monitor

    @impl true
    def init(_opts \\ []) do
      OpentelemetryPhoenix.setup()
    end
  end
end
