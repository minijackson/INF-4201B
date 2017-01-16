defmodule Server.Preamble do

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
        Enum.map(nodes_socket, fn {index, node} ->
          {:ok, {ip, port}} = :inet.peername node
          {:ok, {:hostent, hostname, _, _, _, _}} = :inet.gethostbyaddr ip
          "#{index}: #{hostname}:#{port} "
        end)
      }"
    end

    {:ok, index, my_socket, nodes_socket}
  end

  defp try_listen(nodes, index \\ 0)

  defp try_listen([], index), do: :error

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

  defp connect_nodes([], index), do: []
  defp connect_nodes([node | rest], index) do
    socket = connect_node(node)
    [{index, socket} | connect_nodes(rest, index + 1)]
  end

  defp connect_node({address, port}) do
    {:ok, socket} = :gen_tcp.connect(address, port, [:binary, packet: 0, active: false], 100)
    Logger.debug("Connected to #{address}:#{port}")
    socket
  end

  defp accept_nodes([], my_socket, index), do: []
  defp accept_nodes([_node | rest], my_socket, index) do
    socket = accept_node(my_socket)
    [{index, socket} | accept_nodes(rest, my_socket, index + 1)]
  end

  defp accept_node(my_socket) do
    {:ok, socket} = :gen_tcp.accept(my_socket)
    Logger.debug(fn ->
      {:ok, {ip, port}} = :inet.peername socket
      {:ok, {:hostent, hostname, _, _, _, _}} = :inet.gethostbyaddr ip
      "Accepted connection: #{hostname}:#{port}"
    end)
    socket
  end

end
