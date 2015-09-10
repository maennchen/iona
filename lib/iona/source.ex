defmodule Iona.Source do

  @moduledoc false

  defstruct [:path, :content, :include]

  @type t :: %__MODULE__{path: Path.t, content: Iona.tex_t, include: [Path.t]}

end
