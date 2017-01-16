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
    {:ok, index, my_socket, nodes_socket} = Server.Preamble.start()
    Logger.info("Everybody is connected, starting application")
  end

end
