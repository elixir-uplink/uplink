defmodule Uplink.Monitors.Phoenix do
  use Uplink.Monitor

  @default_buckets [
    5,
    10,
    20,
    50,
    100,
    200,
    500,
    :timer.seconds(1),
    :timer.seconds(1.5),
    :timer.seconds(2),
    :timer.seconds(5),
    :timer.seconds(10)
  ]
  @default_socket_buckets [
    1,
    2,
    5,
    10,
    20,
    50,
    100,
    200,
    500,
    :timer.seconds(1),
    :timer.seconds(1.5),
    :timer.seconds(2),
    :timer.seconds(5),
    :timer.seconds(10),
    :timer.seconds(15),
    :timer.seconds(20),
    :timer.seconds(25),
    :timer.seconds(30)
  ]
  @moduledoc """
  Phoenix definitions. Include these if using Phoenix.

  ## Options

  * `:buckets` - Buckets override. Default: #{inspect(@default_buckets)}
  * `:socket_buckets` - Socket buckets override. Default: #{inspect(@default_socket_buckets)}
  * `:channel_join_warn_threshold` - Slow channel join warning threshold. Time in ms. Default: 250
  * `:channel_event_warn_threshold` - Slow channel event warning threshold. Time in ms. Default: 100

  ## Definitions

  * `http.request.duration.ms` - Phoenix endpoint duration - Total time of the request
    * Type: `Telemetry.Metrics.Distribution.t()`
    * Tags: [:http_status, :method]
    * Buckets: #{inspect(@default_buckets)}
  * `phoenix.router_dispatch.duration.ms` - Phoenix endpoint duration - Total time of the request
    * Type: `Telemetry.Metrics.Distribution.t()`
    * Tags: [:http_status, :method, :route]
    * Buckets: #{inspect(@default_buckets)}
  * `phoenix.error_rendered.total` - Phoenix errors rendered total - Total number of errors rendered
    * Type: `Telemetry.Metrics.Counter.t()`
    * Tags: [:http_status]
  * `phoenix.socket_connected.duration.ms` - Phoenix socket connected duration - Time spent connecting a socket
    * Type: `Telemetry.Metrics.Distribution.t()`
    * Tags: [:result]
    * Buckets: #{inspect(@default_socket_buckets)}
  * `phoenix.channel_joined.duration.ms` - Phoenix channel joined duration - Time spent joining a channel
    * Type: `Telemetry.Metrics.Distribution.t()`
    * Tags: [:channel, :result]
    * Buckets: #{inspect(@default_socket_buckets)}
  * `phoenix.channel_handled_in.duration.ms` - Phoenix channel handled in duration - Time spent handling an in event
    * Type: `Telemetry.Metrics.Distribution.t()`
    * Tags: [:channel, :event]
    * Buckets: #{inspect(@default_socket_buckets)}
  """

  require Logger

  import Telemetry.Metrics, only: [counter: 2, distribution: 2]

  @impl true
  def init(opts \\ []) do
    attach_events(opts)
  end

  def handle_event([:phoenix, :channel_joined], measurements, meta, config) do
    duration = System.convert_time_unit(measurements.duration, :native, :millisecond)

    if duration > config.threshold do
      log_data = %{
        title: "Slow phoenix channel join",
        duration: duration,
        result: meta.result,
        socket_info:
          Map.take(meta.socket, [
            :channel,
            :endpoint,
            :handler,
            :id,
            :join_ref,
            :joined,
            :pubsub_server,
            :serializer,
            :topic,
            :transport
          ])
      }

      _ =
        log_data
        |> Jason.encode!()
        |> Logger.warn()

      :ok
    end

    :ok
  end

  def handle_event([:phoenix, :channel_handled_in], measurements, meta, config) do
    duration = System.convert_time_unit(measurements.duration, :native, :millisecond)

    if duration > config.threshold do
      log_data = %{
        title: "Slow phoenix channel event",
        duration: duration,
        event: meta.event,
        socket_info:
          Map.take(meta.socket, [
            :channel,
            :endpoint,
            :handler,
            :id,
            :join_ref,
            :joined,
            :pubsub_server,
            :serializer,
            :topic,
            :transport
          ])
      }

      _ =
        log_data
        |> Jason.encode!()
        |> Logger.warn()

      :ok
    end

    :ok
  end

  defp default_options do
    [
      buckets: @default_buckets,
      socket_buckets: @default_socket_buckets,
      channel_join_warn_threshold: 250,
      channel_event_warn_threshold: 100
    ]
  end

  defp attach_events(opts) do
    final_opts = Keyword.merge(default_options(), opts)

    join_threshold = Keyword.fetch!(final_opts, :channel_join_warn_threshold)

    :telemetry.attach(
      "phoenix_slow_join_handler",
      [:phoenix, :channel_joined],
      &__MODULE__.handle_event/4,
      %{threshold: join_threshold}
    )

    event_threshold = Keyword.fetch!(final_opts, :channel_event_warn_threshold)

    :telemetry.attach(
      "phoenix_slow_event_handler",
      [:phoenix, :channel_handled_in],
      &__MODULE__.handle_event/4,
      %{threshold: event_threshold}
    )
  end

  @impl true
  def metric_definitions(opts \\ []) do
    final_opts = Keyword.merge(default_options(), opts)

    buckets = Keyword.fetch!(final_opts, :buckets)
    socket_buckets = Keyword.fetch!(final_opts, :socket_buckets)

    [
      distribution("phoenix.endpoint.duration.ms",
        event_name: [:phoenix, :endpoint, :stop],
        measurement: :duration,
        unit: {:native, :millisecond},
        reporter_options: [buckets: buckets],
        description: "Phoenix endpoint duration - Total time of the request",
        tags: [:http_status, :method],
        tag_values: fn %{conn: conn} ->
          %{
            http_status: conn.status,
            method: conn.method
          }
        end
      ),
      distribution("phoenix.router_dispatch.duration.ms",
        event_name: [:phoenix, :router_dispatch, :stop],
        measurement: :duration,
        unit: {:native, :millisecond},
        reporter_options: [buckets: buckets],
        description: "Phoenix endpoint duration - Total time of the request",
        tags: [:http_status, :method, :route],
        tag_values: fn %{conn: conn, route: route} ->
          %{
            http_status: conn.status,
            method: conn.method,
            route: route
          }
        end
      ),
      counter("phoenix.error_rendered.total",
        event_name: [:phoenix, :error_rendered],
        measurement: :duration,
        unit: :"1",
        description: "Phoenix errors rendered total - Total number of errors rendered",
        tags: [:http_status],
        tag_values: fn %{status: status} ->
          %{
            http_status: status
          }
        end
      ),
      distribution("phoenix.socket_connected.duration.ms",
        event_name: [:phoenix, :socket_connected],
        measurement: :duration,
        unit: {:native, :millisecond},
        reporter_options: [buckets: socket_buckets],
        description: "Phoenix socket connected duration - Time spent connected a socket",
        tags: [:result]
      ),
      distribution("phoenix.channel_joined.duration.ms",
        event_name: [:phoenix, :channel_joined],
        measurement: :duration,
        unit: {:native, :millisecond},
        reporter_options: [buckets: socket_buckets],
        description: "Phoenix channel joined duration - Time spent joining a channel",
        tags: [:channel, :result],
        tag_values: fn %{result: result, socket: socket} ->
          %{
            result: result,
            channel: socket.channel
          }
        end
      ),
      distribution("phoenix.channel_handled_in.duration.ms",
        event_name: [:phoenix, :channel_handled_in],
        measurement: :duration,
        unit: {:native, :millisecond},
        reporter_options: [buckets: socket_buckets],
        description: "Phoenix channel handled in duration - Time spent handling an in event",
        tags: [:channel, :event],
        tag_values: fn %{event: event, socket: socket} ->
          %{
            event: event,
            channel: socket.channel
          }
        end
      )
    ]
  end
end
