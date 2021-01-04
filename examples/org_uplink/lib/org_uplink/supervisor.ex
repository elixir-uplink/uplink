defmodule OrgUplink.Supervisor do
  @moduledoc false
  use Supervisor

  alias Uplink.Monitors

  def start_link(init_args) do
    Supervisor.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  @impl true
  def init(args) do
    args = ensure_options(args)

    children = [
      {
        Uplink,
        [
          monitors: [
            Monitors.VM | args[:monitors]
          ],
          metric_definitions: args[:metric_definitions],
          poller_specs: args[:poller_specs],
          reporters: [
            {TelemetryMetricsPrometheus,
             [
               port: Keyword.get(args[:prometheus], :port, 9568)
             ]}
          ]
        ]
      }
    ]

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
end
