defmodule Iona.Template do

  @moduledoc false

  defstruct [:body, :body_path, :content, :include, :helpers]

  @type t :: %__MODULE__{body: Iona.eex_tex_t, body_path: Path.t, content: iodata, include: [Path.t], helpers: [atom]}

  @spec fill(assigns :: Keyword.t | Map.t, template :: t) :: {:ok, t} | {:error, binary}
  def fill(assigns, %{body: body} = template) when is_binary(body) do
    {:ok, %{template | content: eval(prepare(body, template), assigns)}}
  end
  def fill(assigns, %{body_path: path} = template) when is_binary(path) do
    case File.read(path) do
      {:ok, data} -> {:ok, %{template | content: eval(prepare(data, template), assigns, file: path)}}
      _ -> {:error, "Could not read template at path #{path}"}
    end
  end
  def fill(_assigns, _template) do
    {:error, "Invalid template"}
  end

  @spec prepare(raw :: Iona.eex_tex_t, template :: Iono.Template.t) :: Iona.eex_tex_t
  defp prepare(raw, %{helpers: helpers}) do
    bootstrap(helpers |> List.wrap) <> raw
  end

  @spec bootstrap(helpers :: [atom]) :: binary
  defp bootstrap(helpers) do
    Iona.Config.helpers ++ helpers
    |> Enum.map(&("<% import #{&1} %>"))
    |> Enum.join
  end

  defp eval(body, assigns, options \\ []) do
    opts = options |> Keyword.put(:engine, Iona.Template.Engine)
    EEx.eval_string(body, [assigns: assigns], opts)
    |> unwrap
  end

  @spec unwrap(wrapped :: {:safe, Iona.tex_t}) :: Iona.tex_t
  defp unwrap({:safe, body}), do: body
  @spec unwrap(not_wrapped :: Iona.tex_t) :: Iona.tex_t
  defp unwrap(body), do: body

end
