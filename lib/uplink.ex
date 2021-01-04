defmodule Uplink do
  @moduledoc """
  A simple abstraction for standardized observability with telemetry and more.

  Uplink provides a simple abstraction for configuring observability for libraries
  and applications. The heart of Uplink is the `Uplink.Monitor` which provides a
  standard template for common observability needs such as creating Telemetry.Metrics
  definitions, telemetry pollers, or setting up other custom observability requirements.

  The most common challenge when getting started with telemetry is understanding where
  to start, what all the libraries do, and how they all fit together. This creates a
  high learning curve while leaving a huge gap at organizations where most developers
  just want a simple "drop-in" solution for observability that meets the org's requirements.

  Uplink can be used on its own in simple personal projects or as the basis for a standard
  "drop-in" library with a simple abstraction containing standard monitors for your
  organization, such as your Telemetry.Metrics reporter of choice, BEAM VM measurements,
  or Phoenix measurements, all conforming to your org's metric naming conventions or
  other standard practices.

  ## Usage

    # application supervisor
    children = [
      {
        Uplink, [
          monitors: [
            {MyMonitors.Ecto, [:my_repo]},
            Uplink.Monitors.VM
          ],
          pollers: [
            {10, [{TestModule, :test_emitter, []}]}
          ],
          metric_definitions: [
            Telemetry.Metrics.counter("poller.test.event.lasers")
          ],
          reporters: [
            Telemetry.Metrics.ConsoleReporter
          ]
        ]
      }
    ]
  """

  @typedoc """
  An MFA tuple for the poller to execute.
  """
  @type measurement :: {module :: module(), function :: atom(), args :: keyword()}

  @typedoc """
  A list of `t:TelemetryMetrics.t/0` definitions.
  """
  @type metric_definitions :: [Telemetry.Metrics.t()]

  @typedoc """
  A module or two-element tuple consisting of a module and arguments to be
  supplied to the monitor. Any arguments passed are passed to all callbacks
  in the monitor.
  """
  @type monitor :: module() | {module :: module(), args :: keyword()}
  @type monitors :: [monitor()]

  @typedoc """
  Time in ms between poller executions.

  Example: `:timer.seconds(5)`
  """
  # move to :telemetry_poller.period() once released https://github.com/beam-telemetry/telemetry_poller/pull/50
  @type period :: pos_integer()

  @typedoc """
  A shorthand specification for listing a number of pollers to be executed at
  a shared interval.

  Example: `{:timer.seconds(5), [{MyApp.Telemetry, :emit_stats, []}]}`
  """
  @type poller_spec :: {period(), [measurement()]}
  @type poller_specs :: [poller_spec()]

  @typedoc """
  A module or two-element tuple consisting of a reporter and arguments to be
  passed to the reporter,

  Example: `{TelemetryMetricsPrometheus, [port: 9568]}`
  """
  @type reporter_spec :: module() | {module :: module(), args :: keyword()}
  @type reporter_specs :: [reporter_spec()]

  @type option ::
          {:metric_definitions, metric_definitions()}
          | {:monitors, monitors()}
          | {:poller_specs, poller_specs()}
          | {:reporters, reporter_specs()}

  @typedoc """
  Valid options. No options are required but a monitor and/or monitor are the
  minimum required to do anything.

  * `:metric_definitions` - a list of additional `t:Telemetry.Metrics.t/0` definitions not
  exposed by monitors.
  * `:monitors` - a list of `t:monitor/0` to use.
  * `:poller_specs` - a list of additoinal `t:poller_spec/0` not exposed by monitors.
  * `:reporters` - a list of `Telemetry.Metrics` reporters, usually 0 or 1.
  """
  @type options :: [option()]

  @doc """
  Returns the child spec for running Uplink under a supervisor.

  Example:

      children = [
        {Uplink, options}
      ]

  See `t:options/0` for a list of available options.
  """
  @spec child_spec(options()) :: Supervisor.child_spec()
  def child_spec(opts) do
    id =
      case Keyword.get(opts, :name, :uplink) do
        name when is_atom(name) -> name
        {:global, name} -> name
        {:via, _, name} -> name
      end

    spec = %{
      id: id,
      start: {Uplink.Supervisor, :start_link, [opts]},
      type: :supervisor
    }

    Supervisor.child_spec(spec, [])
  end
end
