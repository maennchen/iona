defmodule Iona.Template do

  @moduledoc false

  defstruct [:body, :body_path, :content, :include]

  @type t :: %__MODULE__{body: Iona.eex_tex_source, body_path: Path.t, content: Iona.tex_source, include: [Path.t]}

  @spec fill(assigns :: Keyword.t | Map.t, template :: t) :: {:ok, t} | {:error, binary}
  def fill(assigns, %{body: body} = template) when is_binary(body) do
    {:ok, %{template | content: eval(prepare(body), assigns)}}
  end
  def fill(assigns, %{body_path: path} = template) when is_binary(path) do
    case File.read(path) do
      {:ok, data} -> {:ok, %{template | content: eval(prepare(data), assigns, file: path)}}
      _ -> {:error, "Could not read template at path #{path}"}
    end
  end
  def fill(_assigns, _template) do
    {:error, "Invalid template"}
  end

  @spec prepare(raw :: Iona.eex_tex_source) :: Iona.eex_tex_source
  defp prepare(raw) do
    bootstrap <> raw
  end

  @spec bootstrap :: binary
  defp bootstrap do
    Iona.Config.helpers
    |> Enum.map(&("<% import #{&1} %>"))
    |> Enum.join
  end

  defp eval(body, assigns, options \\ []) do
    opts = options |> Keyword.put(:engine, Iona.Template.Engine)
    EEx.eval_string(body, [assigns: assigns], opts)
    |> unwrap
  end

  defp unwrap({:safe, body}), do: body |> IO.iodata_to_binary
  defp unwrap(body), do: body |> IO.iodata_to_binary

end
