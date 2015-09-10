defmodule Iona.Config do
  @moduledoc false

  @doc """
  The processors by format
  """
  def processors do
    Application.get_env(:iona, :processors, [])
  end

  @doc """
  The helpers
  """
  def helpers do
    Application.get_env(:iona, :helpers, []) |> List.wrap
  end

  @doc """
  The default pre-processing pipeline
  """
  def preprocess do
    Application.get_env(:iona, :preprocess, [])
  end

end
