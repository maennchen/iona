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

  def handle_call(:pop, _from, [h|t]) do
    {:reply, h, t}
  end

  def handle_cast({:push, item}, state) do
    {:noreply, [item|state]}
  end

end
