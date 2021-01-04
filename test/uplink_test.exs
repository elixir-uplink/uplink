defmodule UplinkTest do
  use ExUnit.Case
  doctest Uplink

  test "works with basic settings" do
    spec = {
      Uplink,
      [
        monitors: [
          Uplink.Monitors.VM
        ]
      ]
    }

    {:ok, _} = start_supervised(spec)
  end

  test "accepts options for monitors and reporters" do
    {:ok, device} = StringIO.open("")

    spec = {
      Uplink,
      [
        monitors: [
          {Uplink.Monitors.VM, [poller_interval: 10]}
        ],
        reporters: [
          {Telemetry.Metrics.ConsoleReporter, [device: device]}
        ]
      ]
    }

    {:ok, _} = start_supervised(spec)
    Process.sleep(50)

    {_in, out} = StringIO.contents(device)

    assert out =~ "Metric measurement: :processes_used"
  end
end
