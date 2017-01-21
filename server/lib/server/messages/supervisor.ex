defmodule Server.Messages.Supervisor do
  @moduledoc """
  Documentation for Server.Messages.Supervisor.
  """

  use Supervisor
  require Logger

  def start_link do
    Logger.debug("Starting messages supervisor")
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def listen(nodes) do
    Enum.each(nodes, fn node ->
      Supervisor.start_child(__MODULE__, [node])
    end)
  end

  def init(:ok) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Server.Messages, [])
    ]

    opts = [strategy: :simple_one_for_one, name: Server.Messages.Supervisor]
    supervise(children, opts)
  end

end
