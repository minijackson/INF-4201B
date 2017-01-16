defmodule Server.Preamble do

  require Logger

  def start() do
    nodes = Application.get_env(:server, :nodes)
    {:ok, index, my_socket} = try_listen(nodes)

    left_nodes_socket = nodes
                        |> Enum.take(index)
                        |> Enum.map(&connect_node/1)

    right_nodes_socket = nodes
                         |> Enum.drop(index + 1)
                         |> Enum.map(fn _node -> accept_node(my_socket) end)

    nodes_socket = left_nodes_socket ++ right_nodes_socket
  end

  defp try_listen(nodes, index \\ 0)

  defp try_listen([], index), do: :error

  defp try_listen([{hostname, port} | rest], index) do
    {:ok, my_hostname} = :inet.gethostname

    if hostname == my_hostname do
      case :gen_tcp.listen(port, [:binary, packet: 0, active: :false, reuseaddr: true]) do
        {:ok, socket} ->
          Logger.info("Listening to port #{port}")
          {:ok, index, socket}
        {:error, _error} -> try_listen(rest, index + 1)
      end
    else
      try_listen(rest, index + 1)
    end
  end

  defp connect_node({address, port}) do
    {:ok, socket} = :gen_tcp.connect(address, port, [:binary, packet: 0, active: false], 100)
    Logger.debug("Connected to #{address}:#{port}")
    socket
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
