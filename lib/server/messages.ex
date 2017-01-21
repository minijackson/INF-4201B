defmodule Server.Messages do
  @moduledoc """
  Documentation for Server.Messages.
  """

  require Logger

  def start_link(node) do
    Logger.debug("Listening to: #{inspect node}")
    {:ok, spawn_link(__MODULE__, :listen, [node])}
  end

  def listen({index, _request_socket, recv_socket} = node) do
    case :gen_tcp.recv(recv_socket, 0) do
      {:ok, message} ->
        Logger.debug("Received message: #{message}")
        msg_type = parse(message, index)
        reply(recv_socket, msg_type)
        listen(node)
    end
  end

  defp parse(message, index) do
    case message do
      << "request:", params :: binary >> ->
        ts = String.to_integer(params)
        Logger.info("Received request from node #{index} with timestamp #{ts}")
        Server.Queue.append({index, ts})
        Server.Timestamp.increment(ts)
        :request
      << "finish:", params :: binary >> ->
        ts = String.to_integer(params)
        Logger.info("Node #{index} finished its critical section with timestamp #{ts}")
        Server.Queue.remove(index)
        Server.Timestamp.increment(ts)
        :finish
    end
  end

  defp reply(socket, msg_type) do
    :gen_tcp.send(socket, "ack:#{msg_type}")
  end

  def send_all_request(nodes) do
    Logger.info("Sending request with timestamp: #{Server.Timestamp.now()}")
    Enum.each(nodes, &(send_request(&1)))
  end

  defp send_request({target_index, request_socket, _recv_socket}) do
    ts = Server.Timestamp.now()
    Logger.debug("Sending request to #{target_index} with timestamp: #{ts}")
    :gen_tcp.send(request_socket, "request:#{ts}")
    {:ok, "ack:request"} = :gen_tcp.recv(request_socket, 0)
    Logger.debug("Acknowledge received from #{target_index}")
  end

  def send_all_finish(nodes) do
    Logger.info("Sending finish wit timestamp: #{Server.Timestamp.now()}")
    Enum.each(nodes, &send_finish/1)
  end

  defp send_finish({target_index, request_socket, _recv_socket}) do
    ts = Server.Timestamp.now()
    Logger.debug("Sending finish to #{target_index} with timestamp: #{ts}")
    :gen_tcp.send(request_socket, "finish:#{ts}")
    {:ok, "ack:finish"} = :gen_tcp.recv(request_socket, 0)
    Logger.debug("Acknowledge received from #{target_index}")
  end

end
