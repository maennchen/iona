defmodule Iona.Worker do
  use GenServer

  @moduledoc false

  def server do
    Process.whereis(__MODULE__) ||
      raise "could not find process Iona.Worker. Have you started the :iona application?"
  end

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  ## Callbacks

  @impl GenServer
  def init(init_arg) do
    {:ok, init_arg}
  end

  @impl GenServer
  def handle_call(:pop, _from, [h|t]) do
    {:reply, h, t}
  end

  @impl GenServer
  def handle_cast({:push, item}, state) do
    {:noreply, [item|state]}
  end
end
