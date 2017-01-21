defmodule Server.Timestamp do
  @moduledoc ~S"""
  Documentation for Server.Timestamp.
  """

  def start_link do
    Agent.start_link(fn -> 0 end, name: __MODULE__)
  end

  def now do
    Agent.get(__MODULE__, &(&1))
  end

  def increment do
    Agent.get_and_update(__MODULE__, fn prev_value ->
      ts = prev_value + 1
      {ts, ts}
    end)
  end

  def increment(value) do
    Agent.get_and_update(__MODULE__, fn prev_value ->
      ts = max(value, prev_value) + 1
      {ts, ts}
    end)
  end

end
