defmodule Iona.Config do
  @moduledoc false

  defp get(key) do
    Application.get_env(:iona, key, [])
    |> List.wrap
    |> Enum.find_value(&runtime_value/1)
  end

  def processors do
    Application.get_env(:iona, :processors, [])
  end

  defp runtime_value({:system, env_key}) do
    System.get_env(env_key)
  end
  defp runtime_value(value), do: value

end
