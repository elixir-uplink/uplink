defmodule OrgUplink do
  @moduledoc """
  Documentation for our org's Uplink implementation.

  """

  @doc false
  def child_spec(opts) do
    id =
      case Keyword.get(opts, :name, :uplink) do
        name when is_atom(name) -> name
        {:global, name} -> name
        {:via, _, name} -> name
      end

    spec = %{
      id: id,
      start: {OrgUplink.Supervisor, :start_link, [opts]},
      type: :supervisor
    }

    Supervisor.child_spec(spec, [])
  end
end
