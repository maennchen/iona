defmodule Iona.Document do
  defstruct [:source, :source_path, :format, :output]

  @type t :: %Iona.Document{}

end
