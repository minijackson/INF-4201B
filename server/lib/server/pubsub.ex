defmodule Server.PubSub do

  use GenServer

  require Logger

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, {nil, nil}}
  end

  def subscribe(subscriber) do
    GenServer.call(__MODULE__, {:subscribe, subscriber})
  end

  def unsubscribe do
    GenServer.call(__MODULE__, :unsubscribe)
  end

  def publish(params) do
    GenServer.call(__MODULE__, {:publish, params})
  end

  def handle_call({:subscribe, subscriber}, _from, {_subscriber, first_index}) do
    send_if_first(subscriber, first_index)
    {:reply, :ok, {subscriber, first_index}}
  end

  def handle_call(:unsubscribe, _from, {_subscriber, first_index}) do
    {:reply, :ok, {nil, first_index}}
  end

  def handle_call({:publish, first_index = first_elem}, _from, {subscriber, _first_index}) do
    send_if_first(subscriber, first_index)
    {:reply, :ok, {subscriber, first_elem}}
  end

  defp send_if_first(_subscriber, nil), do: nil
  defp send_if_first(nil, _first_index), do: nil

  defp send_if_first({index, pid}, first_index) do
    if index == first_index do
        Logger.debug("#{index} is first, sending to PID #{inspect pid}")
        send pid, :ok
    end
  end

end
