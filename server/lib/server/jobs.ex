defmodule Server.Jobs do
  @moduledoc """
  Documentation for Server.Jobs.
  """

  require Logger

  alias Server.Messages
  alias Server.Timestamp
  alias Server.Queue
  alias Server.PubSub

  def start_link(nodes, index) do
    {:ok, spawn_link(fn -> init(nodes, index) end)}
  end

  def init(nodes, index) do
    Process.register(self(), __MODULE__)
    main_loop(nodes, index)
  end

  defp main_loop(nodes, index) do
    sleep_time = :rand.uniform(10) * 1_000
    :timer.sleep sleep_time

    request(nodes, index)

    main_loop(nodes, index)
  end

  defp request(nodes, index) do
    PubSub.subscribe({index, self()})

    Queue.append({index, Timestamp.now()})
    Messages.send_all_request(nodes)

    wait_my_turn()
    PubSub.unsubscribe()

    Logger.warn("Beginning critical section")
    :timer.sleep(3_000)
    Logger.warn("Finishing critical section")
    Timestamp.increment()

    Queue.remove(index)
    Messages.send_all_finish(nodes)
  end

  defp wait_my_turn() do
    Logger.info("Waiting my turn")
    receive do
      :ok -> :ok
    end
  end

end
