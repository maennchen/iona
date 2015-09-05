defmodule Iona do
  @moduledoc File.read!("#{__DIR__}/../README.md")

  use Application
  @doc false
  def start(_type, _args) do
    Iona.Supervisor.start_link()
  end

  @type tex :: binary

  @type source_opts :: [
    {:path, Path.t}
  ]

  @doc """
  Define the document source
  """
  @spec source(criteria :: tex) :: Iona.Document.t
  def source(criteria) when is_binary(criteria) do
    %Iona.Document{source: criteria}
  end
  @spec source(criteria :: source_opts) :: Iona.Document.t
  def source(criteria) when is_list(criteria) do
    %Iona.Document{source_path: Keyword.get(criteria, :path, nil)}
  end

  @type processor_name :: binary

  @type processing_opts :: [
    {:preprocess, [processor_name]},
    {:processor, processor_name}
  ]

  @doc """
  Generate a document in format using processing options
  """
  @spec to(doc :: Iona.Document.t,
           format :: atom) :: {:ok, Iona.Document.t} | {:error, binary}
  def to(doc, format), do: to(doc, format, [])

  def to!(doc, format), do: to!(doc, format, [])

  @doc """
  Generate a document in format using processing options
  """
  @spec to(doc :: Iona.Document.t,
           format :: atom,
           opts :: processing_opts) :: {:ok, Iona.Document.t} | {:error, binary}
  def to(%{source: tex} = doc, format, opts) when is_binary(tex) do
    doc |> run(format, opts)
  end
  @spec to(doc :: Iona.Document.t,
           format :: atom,
           opts :: processing_opts) :: {:ok, Iona.Document.t} | {:error, binary}
  def to(%{source_path: path} = doc, format, opts) when is_binary(path) do
    case File.read(path) do
      {:ok, source} -> %{doc | source: source} |> to(format, opts)
      other -> other
    end
  end
  def to(_doc, _format, _opts) do
    {:error, "No :source or :source_path given"}
  end

  def to!(doc, format, opts) do
    {:ok, result} = to(doc, format, opts)
    result
  end


  @doc false
  @spec run(doc :: Iona.Document.t, format :: atom, opts :: processing_opts) :: {:ok, Iona.Document.t} | {:error, binary}
  defp run(doc, format, opts) do
    # TODO
    {:ok, %{doc | output: ""}}
  end

end
