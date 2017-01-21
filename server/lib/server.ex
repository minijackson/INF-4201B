defmodule Server do
  @moduledoc """
  Documentation for Server.
  """

  use Application
  require Logger

  def start(_type, _args) do
    {:ok, index, _my_socket, nodes} = Server.Preamble.start()
    Logger.info("Everybody is connected, starting application")

    import Supervisor.Spec, warn: false

    children = [
      supervisor(Server.Messages.Supervisor, []),
      worker(Server.Jobs, [nodes, index]),
      worker(Server.Timestamp, []),
      worker(Server.Queue, []),
      worker(Server.PubSub, []),
    ]

    opts = [strategy: :one_for_one, name: Server.Supervisor]
    rv = Supervisor.start_link(children, opts)

    Logger.debug "Started main supervisor, listening to nodes"

    Server.Messages.Supervisor.listen(nodes)

    rv
  end

end
