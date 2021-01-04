defmodule Uplink.Monitors.Ecto do
  use Uplink.Monitor

  @default_buckets [5, 10, 20, 50, 100, 200, 500, 1000, 1500, 2000, 5000, 10000]
  @moduledoc """
  Ecto definitions. Include these if using Ecto.

  Keep the prefix consistent among repos. The repo name is captured as a tag
  from the metadata for reporting purposes and can be segregated as such in Grafana.

  ## Options

  * `:buckets` - Buckets override. Default: #{inspect(@default_buckets)}
  * `:query_time_warn_threshold` - Slow Ecto query warning threshold. Time in ms. Default: 100

  ## Definitions

  * `ecto.queue.duration.ms` - Ecto queue duration - Time spent waiting to check out a database connection
    * Type: `Telemetry.Metrics.Distribution.t()`
    * Tags: [:repo]
    * Buckets: #{inspect(@default_buckets)}
  * `ecto.query.duration.ms` - Ecto query duration - Time spent executing the query
    * Type: `Telemetry.Metrics.Distribution.t()`
    * Tags: [:repo]
    * Buckets: #{inspect(@default_buckets)}
  * `ecto.decode.duration.ms` - Ecto decode duration - Time spend decoding the data received from the database
    * Type: `Telemetry.Metrics.Distribution.t()`
    * Tags: [:repo]
    * Buckets: #{inspect(@default_buckets)}
  * `ecto.idle.duration.ms` - Ecto decode duration - Time the connection spent waiting before being checked out for the query
    * Type: `Telemetry.Metrics.Distribution.t()`
    * Tags: [:repo]
    * Buckets: #{inspect(@default_buckets)}
  * `ecto.total.duration.ms` - Ecto query duration - Sum of all the measurements
    * Type: `Telemetry.Metrics.Distribution.t()`
    * Tags: [:repo]
    * Buckets: #{inspect(@default_buckets)}
  """

  require Logger

  import Telemetry.Metrics, only: [distribution: 2]

  @impl true
  def init(opts) do
    prefix = Keyword.fetch!(opts, :repo_prefix)
    attach_events(prefix, opts)
  end

  def handle_event(_, nil, _, _), do: :ok

  def handle_event([_repo, :repo, :query], measures, meta, config) do
    measurements =
      measures
      |> Enum.into(%{})
      |> Map.take([:decode_time, :query_time, :idle_time, :queue_time, :total_time])
      |> Enum.reject(&is_nil(elem(&1, 1)))
      |> Enum.into(%{}, fn {k, v} ->
        {k, System.convert_time_unit(v, :native, :millisecond)}
      end)

    if measurements.total_time > config.threshold do
      query_data = %{
        title: "Slow Ecto Query",
        query: meta.query,
        repo: meta.repo,
        source: meta.source,
        data_source: meta.source
      }

      _ =
        Map.merge(query_data, measurements)
        |> Jason.encode!()
        |> Logger.warn()

      :ok
    end

    :ok
  end

  defp default_options do
    [
      buckets: @default_buckets,
      query_time_warn_threshold: 100
    ]
  end

  defp attach_events(prefix, opts) do
    final_opts = Keyword.merge(default_options(), opts)

    threshold = Keyword.fetch!(final_opts, :query_time_warn_threshold)

    :telemetry.attach(
      "ecto_#{prefix}_slow_query_handler",
      [prefix, :repo, :query],
      &__MODULE__.handle_event/4,
      %{threshold: threshold}
    )
  end

  @impl true
  def metric_definitions(opts) do
    prefix = Keyword.fetch!(opts, :repo_prefix)

    final_opts = Keyword.merge(default_options(), opts)

    buckets = Keyword.fetch!(final_opts, :buckets)

    [
      distribution("ecto.queue.duration.ms",
        event_name: [prefix, :repo, :query],
        measurement: :queue_time,
        unit: {:native, :millisecond},
        reporter_options: [buckets: buckets],
        description:
          "Ecto queue duration - Time spent waiting to check out a database connection",
        tags: [:repo]
      ),
      distribution("ecto.query.duration.ms",
        event_name: [prefix, :repo, :query],
        measurement: :query_time,
        unit: {:native, :millisecond},
        reporter_options: [buckets: buckets],
        description: "Ecto query duration - Time spent executing the query",
        tags: [:repo]
      ),
      distribution("ecto.decode.duration.ms",
        event_name: [prefix, :repo, :query],
        measurement: :decode_time,
        unit: {:native, :millisecond},
        reporter_options: [buckets: buckets],
        description:
          "Ecto decode duration - Time spend decoding the data received from the database",
        tags: [:repo]
      ),
      distribution("ecto.idle.duration.ms",
        event_name: [prefix, :repo, :query],
        measurement: :idle_time,
        unit: {:native, :millisecond},
        reporter_options: [buckets: buckets],
        description:
          "Ecto idle duration - Time the connection spent waiting before being checked out for the query",
        tags: [:repo]
      ),
      distribution("ecto.total.duration.ms",
        event_name: [prefix, :repo, :query],
        measurement: :total_time,
        unit: {:native, :millisecond},
        reporter_options: [buckets: buckets],
        description: "Ecto query duration - Sum of all the measurements",
        tags: [:repo]
      )
    ]
  end
end
