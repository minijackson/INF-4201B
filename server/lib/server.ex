defmodule Server do
  @moduledoc """
  Documentation for Server.
  """

  use Application
  require Logger

  def start(_type, _args) do
    Logger.info "Started"
    {:ok, spawn_link(&begin/0)}
  end

  def begin() do
    nodes_socket = Server.Preamble.start()

    Logger.debug fn ->
      "Total connected nodes: #{
        Enum.map(nodes_socket, fn node ->
          {:ok, {ip, port}} = :inet.peername node
          {:ok, {:hostent, hostname, _, _, _, _}} = :inet.gethostbyaddr ip
          "#{hostname}:#{port} "
        end)
      }"
    end
  end

end
