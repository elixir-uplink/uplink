defmodule Uplink.Monitor do
  @moduledoc """
  A behaviour module for implementing a library or application monitor.

  Uplink Monitors provide a template for the most common requirements to instrument a library
  or application in a consistent manner. These provide a simple abstraction for building
  standard observability patterns for whatever is being monitored while removing the need
  for users to repeatedly define and configure things like `TelemetryMetrics` definitions.

  There are three required callbacks which make up a monitor. The provided macro provides
  default implementations for each, allowing you to only implement what is needed for a
  particular monitor.

  Each callback receives the same argument defined in `t:Uplink.monitor/0`.

  ## Usage

      defmodule MyApp.CustomMonitor do
        using Uplink.Monitor
        # override any callbacks you need

        @impl true
        def init(_) do
          # some setup
          :ok
        end

        @impl true
        def metric_definitions(_) do
          [Telemetry.Metrics.counter("some.event")]
        end

        @impl true
        def poller_specs(_) do
          [
            {:timer.seconds(5), [
              {MyApp.Telemetry, :emit_stats, []}
            ]}
          ]
      end

  See `Uplink.Monitors.VM` for an example implementation.
  """

  @doc """
  Invoked when Uplink is starting.

  It is useful for initializing any custom monitoring for the library or application
  being monitored. Examples include creating `telemetry` handlers to log slow `Ecto` queries
  which exceed a threshold or starting an OpenTelemetry bridge library.

  If the function returns `:error`, Uplink will exit.

  This callback is required.
  """
  @callback init(args :: any()) :: :ok | :error

  @doc """
  Invoked when Uplink is starting.

  It is useful for providing a standard set of `t:Telemetry.Metrics.t/0` definitions
  for the library or application being monitored.

  This callback is required.
  """
  @callback metric_definitions(args :: any()) :: Uplink.metric_definitions()

  @doc """
  Invoked when Uplink is starting.

  It is useful for providing a standard set of `telemetry_poller`s for the library or
  application being monitored. Examples include emitting cache sizes, memory usage, or
  process counts.

  This callback is required.
  """
  @callback poller_specs(args :: any()) :: Uplink.poller_specs()

  defmacro __using__(_options) do
    quote location: :keep do
      @behaviour Uplink.Monitor

      @doc false
      def init(_args), do: :ok

      @doc false
      def metric_definitions(_args), do: []

      @doc false
      def poller_specs(_args), do: []

      defoverridable init: 1, metric_definitions: 1, poller_specs: 1
    end
  end
end
