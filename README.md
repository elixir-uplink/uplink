# Uplink

Uplink makes setup of application monitoring with telemetry as simple as possible. Rather
than having to add and setup several libraries, this package rolls them all up into a single
configurable drop-in to your application tree.

## Installation

```elixir
def deps do
  [
    {:uplink, "~> 0.1"}
  ]
end
```

## Usage

Add Uplink to your application supervision tree and tell it which monitors
it should run. 

```elixir
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
```
See the [docs](https://hexdocs.pm/uplink) for more information.


Copyright (c) 2021 Bryan Naegele
