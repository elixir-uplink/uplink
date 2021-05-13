if Code.ensure_loaded?(SocketDrano) do
  defmodule Uplink.Monitors.SocketDrano do
    use Uplink.Monitor

    @moduledoc """
    SocketDrano definitions. Include these if using SocketDrano.

    ## Options

    ## Definitions

    * `phoenix.socket.count` - Total number of connected Phoenix sockets
    * Type: `Telemetry.Metrics.LastValue.t()`
    """

    import Telemetry.Metrics, only: [last_value: 2]

    @impl true
    def poller_specs(_opts \\ []) do
      [
        {:timer.seconds(5),
         [
           {__MODULE__, :emit_stats, []}
         ]}
      ]
    end

    def emit_stats do
      case SocketDrano.socket_count() do
        :not_running ->
          :ok

        count ->
          :telemetry.execute([:socket_drano, :stats], %{socket_count: count})
      end
    end

    @impl true
    def metric_definitions(_opts \\ []) do
      [
        last_value("phoenix.sockets.count",
          event_name: [:socket_drano, :stats],
          measurement: :socket_count,
          unit: :"1",
          description: "Current number of open Phoenix Sockets"
        )
      ]
    end
  end
end
