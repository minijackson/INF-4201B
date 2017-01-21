defmodule Server.Queue do

  use GenServer

  require Logger

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, []}
  end

  def get_first do
    GenServer.call(__MODULE__, :get_first)
  end

  def append(value) do
    GenServer.call(__MODULE__, {:append, value})
    publish()
  end

  def remove(index) do
    GenServer.call(__MODULE__, {:remove, index})
    publish()
  end

  defp publish do
    case get_first() do
      {index, _ts} ->
        Logger.debug("Publishing #{index}")
        Server.PubSub.publish(index)
      nil -> nil
    end
  end

  # GenServer callbacks

  def handle_call(:get_first, _from, []) do
    {:reply, nil, []}
  end

  def handle_call(:get_first, _from, queue) do
    {:reply,
      Enum.min_by(queue, fn {_index, ts} -> ts end),
      queue}
  end

  def handle_call({:append, value}, _from, queue) do
    {:reply, :ok, Enum.sort([value | queue], &(elem(&1, 0) < elem(&2, 0)))}
  end

  def handle_call({:remove, index}, _from, queue) do
    {:reply, :ok, Enum.reject(queue, fn {candidate_index, _ts} ->
      candidate_index == index
    end)}
  end

end
