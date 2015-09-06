defmodule Iona.Template do

  @moduledoc false

  defstruct [:body, :body_path, :content, :include]

  @type t :: %__MODULE__{body: Iona.eex_tex_source, body_path: Path.t, content: Iona.tex_source, include: [Path.t]}

  @spec fill(assigns :: Keyword.t | Map.t, template :: t) :: {:ok, t} | {:error, binary}
  def fill(assigns, %{body: body} = template) when is_binary(body) do
    {:ok, %{template | content: EEx.eval_string(body, assigns: assigns)}}
  end
  def fill(assigns, %{body_path: path} = template) when is_binary(path) do
    {:ok, %{template | content: EEx.eval_file(path, assigns: assigns)}}
  end
  def fill(_assigns, _template) do
    {:error, "Invalid template"}
  end

end
