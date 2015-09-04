defmodule Iona do
  @moduledoc File.read!("#{__DIR__}/../README.md")

  use Application

  @doc false
  def start(_type, _args) do
    Iona.Supervisor.start_link()
  end

end
