defmodule Iona.Document do
  @moduledoc false

  defstruct [:format, :output_path]

  @type t :: %__MODULE__{format: Iona.supported_format_t(), output_path: Path.t()}

  @spec read(document :: t) :: {:ok, binary} | {:error, File.posix()}
  def read(%{output_path: path}), do: File.read(path)

  @spec read!(document :: t) :: binary
  def read!(%{output_path: path}), do: File.read!(path)

  @spec write(document :: t, destination :: Path.t()) :: :ok | {:error, File.posix()}
  def write(%{output_path: path}, destination), do: File.cp(path, destination)

  @spec write!(document :: t, destination :: Path.t()) :: :ok
  def write!(%{output_path: path}, destination), do: File.cp!(path, destination)
end
