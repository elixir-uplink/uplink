defmodule Uplink.Monitors.VM do
  use TelemetryRegistry
  use Uplink.Monitor

  telemetry_event(%{
    event: [:vm, :stats],
    description: "Emits BEAM system statistics",
    measurements: """
    %{
      context_switches: non_neg_integer,
      gc_count: non_neg_integer,
      gc_bytes_reclaimed: non_neg_integer,
      io_in: non_neg_integer,
      io_out: non_neg_integer,
      reductions: non_neg_integer
    }
    """,
    metadata: "%{}"
  })

  telemetry_event(%{
    event: [:vm, :system_limits],
    description: "Emits BEAM system limits",
    measurements: """
    %{
      atom_limit: non_neg_integer,
      port_limit: non_neg_integer,
      process_limit: non_neg_integer
    }
    """,
    metadata: "%{}"
  })

  @moduledoc """
  Provides telemetry events, pollers for emitting those events, and definitions for
  BEAM VM statistics in addition to the builtins available `telemetry_poller` vm statistics.

  ## Telemetry

  #{telemetry_docs()}
  """

  import Telemetry.Metrics, only: [counter: 2, last_value: 2]

  @impl true
  def init(_opts \\ []), do: :ok

  @impl true
  def poller_specs(opts \\ []) do
    args = Keyword.merge([poller_interval: :timer.seconds(5)], opts)

    [
      {args[:poller_interval],
       [
         :memory,
         :total_run_queue_lengths,
         :system_counts,
         {__MODULE__, :emit_system_limits, []},
         {__MODULE__, :emit_stats, []}
       ]}
    ]
  end

  def emit_system_limits do
    measurements =
      Enum.map(
        [
          :atom_limit,
          :port_limit,
          :process_limit
        ],
        &{&1, :erlang.system_info(&1)}
      )
      |> Enum.into(%{})

    :telemetry.execute([:vm, :system_limits], measurements)
  end

  def emit_stats do
    {context_switches, _} = :erlang.statistics(:context_switches)
    {reductions, _} = :erlang.statistics(:reductions)
    {gc_count, words_reclaimed, _} = :erlang.statistics(:garbage_collection)
    {{:input, input}, {:output, output}} = :erlang.statistics(:io)

    :telemetry.execute([:vm, :stats], %{
      context_switches: context_switches,
      reductions: reductions,
      gc_count: gc_count,
      gc_bytes_reclaimed: words_reclaimed * 8,
      io_in: input,
      io_out: output
    })
  end

  @impl true
  def metric_definitions(_opts \\ []) do
    [
      counter("erlang.vm.context_switches.total",
        event_name: [:vm, :stats],
        measurement: :context_switches,
        unit: :"1",
        description: "Erlang VM - Total context switches"
      ),
      counter("erlang.vm.reductions.total",
        event_name: [:vm, :stats],
        measurement: :reductions,
        unit: :"1",
        description: "Erlang VM - Total reductions"
      ),
      counter("erlang.vm.gc.total",
        event_name: [:vm, :stats],
        measurement: :gc_count,
        unit: :"1",
        description: "Erlang VM - Total garbage collections"
      ),
      counter("erlang.vm.gc.reclaimed.total.bytes",
        event_name: [:vm, :stats],
        measurement: :gc_bytes_reclaimed,
        unit: :byte,
        description: "Erlang VM - Total bytes reclaimed from gc"
      ),
      counter("erlang.vm.io.in.total.bytes",
        event_name: [:vm, :stats],
        measurement: :io_in,
        unit: :byte,
        description: "Erlang VM - Total IO bytes in"
      ),
      counter("erlang.vm.io.out.total.bytes",
        event_name: [:vm, :stats],
        measurement: :io_out,
        unit: :byte,
        description: "Erlang VM - Total IO bytes out"
      ),
      last_value("erlang.vm.memory.usage.bytes",
        event_name: [:vm, :memory],
        measurement: :total,
        unit: :byte,
        description: "Erlang VM - Total memory usage"
      ),
      last_value("erlang.vm.memory.processes.usage.bytes",
        event_name: [:vm, :memory],
        measurement: :processes_used,
        unit: :byte,
        description: "Erlang VM - Total memory used by all processes"
      ),
      last_value("erlang.vm.memory.binaries.usage.bytes",
        event_name: [:vm, :memory],
        measurement: :binary,
        unit: :byte,
        description: "Erlang VM - Total memory used by binaries"
      ),
      last_value("erlang.vm.memory.ets.usage.bytes",
        event_name: [:vm, :memory],
        measurement: :ets,
        unit: :byte,
        description: "Erlang VM - Total memory used by ets tables"
      ),
      last_value("erlang.vm.run_queue_lengths",
        event_name: [:vm, :total_run_queue_lengths],
        measurement: :total,
        unit: :"1",
        description: "Erlang VM - Sum of all schedulers' run queue lengths"
      ),
      last_value("erlang.vm.run_queue_lengths.cpu",
        event_name: [:vm, :total_run_queue_lengths],
        measurement: :cpu,
        unit: :"1",
        description:
          "Erlang VM - Sum of CPU schedulers' run queue lengths, including dirty CPU run queue length"
      ),
      last_value("erlang.vm.system.process.limit",
        event_name: [:vm, :system_limits],
        measurement: :process_limit,
        unit: :"1",
        description: "Erlang VM - Total process limit"
      ),
      last_value("erlang.vm.system.process.usage",
        event_name: [:vm, :system_counts],
        measurement: :process_count,
        unit: :"1",
        description: "Erlang VM - Total process count"
      ),
      last_value("erlang.vm.system.atom.limit",
        event_name: [:vm, :system_limits],
        measurement: :atom_limit,
        unit: :"1",
        description: "Erlang VM - Total atom limit"
      ),
      last_value("erlang.vm.system.atom.usage",
        event_name: [:vm, :system_counts],
        measurement: :atom_count,
        unit: :"1",
        description: "Erlang VM - Total atom count"
      ),
      last_value("erlang.vm.system.port.limit",
        event_name: [:vm, :system_limits],
        measurement: :port_limit,
        unit: :"1",
        description: "Erlang VM - Total port limit"
      ),
      last_value("erlang.vm.system.port.usage",
        event_name: [:vm, :system_counts],
        measurement: :port_count,
        unit: :"1",
        description: "Erlang VM - Total port count"
      )
    ]
  end
end
