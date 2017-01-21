defmodule Server.Preamble do
  @moduledoc """
  Documentation for Server.Preamble.
  """


  require Logger

  def start() do
    nodes = Application.get_env(:server, :nodes)
    {:ok, index, my_socket} = try_listen(nodes)

    left_nodes_socket = nodes
                        |> Enum.take(index)
                        |> connect_nodes(0)

    right_nodes_socket = nodes
                         |> Enum.drop(index + 1)
                         |> accept_nodes(my_socket, index + 1)

    nodes_socket = left_nodes_socket ++ right_nodes_socket

    Logger.debug fn ->
      "Total connected nodes: #{
        Enum.map(nodes_socket, fn {index, request_socket, _recv_socket} ->
          {:ok, {ip, port}} = :inet.peername request_socket
          {:ok, {:hostent, hostname, _, _, _, _}} = :inet.gethostbyaddr ip
          "#{index}: #{hostname}:#{port} "
        end)
      }"
    end

    {:ok, index, my_socket, nodes_socket}
  end

  defp try_listen(nodes, index \\ 0)

  defp try_listen([], _index), do: :error

  defp try_listen([{hostname, port} | rest], index) do
    {:ok, my_hostname} = :inet.gethostname

    if hostname == my_hostname do
      case :gen_tcp.listen(port, [:binary, packet: 0, active: :false, reuseaddr: true]) do
        {:ok, socket} ->
          Logger.info("Listening to port: #{port} with index: #{index}")
          {:ok, index, socket}
        {:error, _error} -> try_listen(rest, index + 1)
      end
    else
      try_listen(rest, index + 1)
    end
  end

  defp connect_nodes([], _index), do: []
  defp connect_nodes([node | rest], index) do
    {request_socket, recv_socket} = connect_node(node)
    [{index, request_socket, recv_socket} | connect_nodes(rest, index + 1)]
  end

  defp connect_node({address, port}) do
    {:ok, recv_socket} = :gen_tcp.connect(address, port, [:binary, packet: 0, active: false], 100)
    {:ok, request_socket} = :gen_tcp.connect(address, port, [:binary, packet: 0, active: false], 100)
    Logger.debug("Connected to #{address}:#{port}")
    {request_socket, recv_socket}
  end

  defp accept_nodes([], _my_socket, _index), do: []
  defp accept_nodes([_node | rest], my_socket, index) do
    {request_socket, recv_socket} = accept_node(my_socket)
    [{index, request_socket, recv_socket} | accept_nodes(rest, my_socket, index + 1)]
  end

  defp accept_node(my_socket) do
    {:ok, request_socket} = :gen_tcp.accept(my_socket)
    {:ok, recv_socket} = :gen_tcp.accept(my_socket)
    Logger.debug(fn ->
      {:ok, {ip, port}} = :inet.peername request_socket
      {:ok, {:hostent, hostname, _, _, _, _}} = :inet.gethostbyaddr ip
      "Accepted connection: #{hostname}:#{port}"
    end)
    {request_socket, recv_socket}
  end

end
