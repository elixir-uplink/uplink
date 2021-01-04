defmodule OrgUplinkTest do
  use ExUnit.Case
  doctest OrgUplink

  alias Uplink.Monitors

  test "works great good" do
    _sup_pid =
      start_supervised!(
        DynamicSupervisor.child_spec(name: MyTestAppRoot.Supervisor, strategy: :one_for_one)
      )

    spec = {
      OrgUplink,
      [
        monitors: [
          {Monitors.Ecto, [repo_prefix: :my_app]},
          Monitors.Phoenix
        ],
        poller_specs: [
          {10, [{TestModule, :test_emitter, []}]}
        ],
        metric_definitions: [
          Telemetry.Metrics.counter("poller.test.event.lasers")
        ],
        prometheus: [port: 9888]
      ]
    }

    {:ok, _bb_pid} = DynamicSupervisor.start_child(MyTestAppRoot.Supervisor, spec)
  end

  test "works great good with defaults" do
    _sup_pid =
      start_supervised!(
        DynamicSupervisor.child_spec(name: MyTestAppRoot.Supervisor, strategy: :one_for_one)
      )

    {:ok, _bb_pid} = DynamicSupervisor.start_child(MyTestAppRoot.Supervisor, Uplink)
  end

  defmodule TestModule do
    def test_emitter do
      :telemetry.execute([:poller, :test, :event], %{lasers: 5})
    end
  end
end
