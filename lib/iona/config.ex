defmodule Iona.Config do
  @moduledoc false

  @spec processors :: [Iona.processor_name]
  def processors do
    Application.get_env(:iona, :processors, [])
  end

  @spec preprocess :: [Iona.preprocessor_name]
  def preprocess do
    Application.get_env(:iona, :preprocess, [])
  end

end
