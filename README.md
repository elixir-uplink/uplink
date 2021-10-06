[![EEF Observability WG project](https://img.shields.io/badge/EEF-Observability-black)](https://github.com/erlef/eef-observability-wg)
[![Hex.pm](https://img.shields.io/hexpm/v/uplink)](https://hex.pm/packages/uplink)
![Build Status](https://github.com/elixir-uplink/uplink/workflows/Tests/badge.svg)

# Uplink

Uplink makes setup of application monitoring with telemetry as simple as possible. Rather
than having to add and setup several libraries, this package rolls them all up into a single
configurable drop-in to your application tree.

## Installation

```elixir
def deps do
  [
    {:uplink, "~> 0.2"}
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
        {MyMonitors.Ecto, [repo_prefix: :my_repo]},
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

## Uplink Monitors

Monitors by the community, for the community!

## Usage

Uplink Monitors are meant to be copied and pasted into your project as a starting point because 
preferences amongst individuals and organizations around metrics can vary widely. The important
thing is to have a jumping-off point and can learn patterns and practices from others. These
aren't one-size-fits-all, so make them your own and share your learnings with others!

In the [monitors](https://github.com/elixir-uplink/monitors) folder you'll find monitors for popular
libraries which have been compiled over the past few years. They've worked quite well, so
enjoy!

Create a PR to add a link to your own examples in the README or a monitor for a library
not already covered.

### Community Links



Copyright (c) 2021 Bryan Naegele
