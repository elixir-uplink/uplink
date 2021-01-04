defmodule Uplink.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(init_args) do
    Supervisor.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  @impl true
  def init(args) do
    args = ensure_options(args)

    monitors = args[:monitors]
    metrics = metric_definitions(monitors) ++ args[:metric_definitions]

    user_pollers = poller_specs(args[:poller_specs])
    monitor_pollers = monitor_pollers(monitors)

    reporters = reporter_specs(args[:reporters], metrics)

    :ok = init_monitors(monitors)

    children =
      (reporters ++ user_pollers ++ monitor_pollers)
      |> Enum.reject(&match?([], &1))

    Supervisor.init(children, strategy: :one_for_one)
  end

  def ensure_options(args) do
    Keyword.merge(default_options(), args)
  end

  def default_options do
    [
      monitors: [],
      metric_definitions: [],
      reporters: [],
      poller_specs: []
    ]
  end

  defp init_monitors(monitors) do
    status =
      Enum.reduce(monitors, [], fn
        {monitor, args}, results -> [apply(monitor, :init, [args]) | results]
        monitor, results -> [apply(monitor, :init, [[]]) | results]
      end)
      |> Enum.all?(&(&1 == :ok))

    if status, do: :ok, else: :error
  end

  defp reporter_specs(reporters, metrics) do
    reporters
    |> Enum.map(fn
      {reporter, args} -> {reporter, Keyword.put(args, :metrics, metrics)}
      reporter -> {reporter, [metrics: metrics]}
    end)
  end

  defp metric_definitions(monitors) do
    Enum.reduce(monitors, [], fn
      {monitor, args}, defs -> apply(monitor, :metric_definitions, [args]) ++ defs
      monitor, defs -> apply(monitor, :metric_definitions, [[]]) ++ defs
    end)
  end

  defp monitor_pollers(monitors) do
    Enum.map(monitors, fn
      {monitor, args} -> apply(monitor, :poller_specs, [args])
      monitor -> apply(monitor, :poller_specs, [[]])
    end)
    |> List.flatten()
    |> poller_specs()
  end

  defp poller_specs(pollers) do
    Enum.map(pollers, fn {period, measurements} ->
      {:telemetry_poller,
       period: period, measurements: measurements, name: :"#{System.system_time()}"}
    end)
  end
end
