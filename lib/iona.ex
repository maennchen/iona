defmodule Iona do
  @moduledoc File.read!("#{__DIR__}/../README.md")

  use Application
  @doc false
  def start(_type, _args) do
    Iona.Supervisor.start_link()
  end

  @doc """
  Fill in a template with assignments, with TeX escaping support

  ```
  [title: "An Article", author: "Bruce Williams"]
  |> Iona.template(path: "/path/to/article.tex")
  |> Iona.write("/path/to/article.pdf")
  ```
  """
  @type template_opts :: [
    {:path, Path.t}
  ]

  @spec template(assigns :: Keyword.t, criteria :: eex_tex_t) :: Iona.Template.t
  def template(assigns, criteria) when is_binary(criteria) do
    case assigns |> Iona.Template.fill(%Iona.Template{body: criteria}) do
      {:ok, template} -> template
      _ -> nil
    end
  end

  @spec template(assigns :: Keyword.t, criteria :: template_opts) :: Iona.Template.t
  def template(assigns, criteria) when is_list(criteria) do
    template = %Iona.Template{body_path: Keyword.get(criteria, :path),
                              helpers: Keyword.get(criteria, :helpers, [])}
    case assigns |> Iona.Template.fill(template) do
      {:ok, template} -> template
      _ -> nil
    end
  end

  # Note: The \\ in the example below is escaping to support ExDoc.
  # In the actual LaTeX source, this would be \documentclass
  @doc """
  Define the document source, either as a raw TeX binary or the path to a `.tex` file.

  As raw TeX:

  ```
  Iona.source("\\documentclass[12pt]{article} ...")
  ```

  From a file:

  ```
  Iona.source(path: "/path/to/document.tex")
  ```

  When providing a file path, you can also define additional files needed
  for processing. They will be copied to the temporary directory where processing
  will take place.

  ```elixir
  Iona.source(path: "/path/to/document.tex",
              include: ["/path/to/document.bib",
                        "/path/to/documentclass.sty"])
  ```

  However, when possible, files should be placed in the search path of your TeX
  installation.
  """
  @type source_opts :: [
    {:path, Path.t},
    {:include, [Path.t]}
  ]

  @spec source(criteria :: binary) :: Iona.Source.t
  def source(criteria) when is_binary(criteria) do
    %Iona.Source{content: criteria}
  end
  @spec source(criteria :: source_opts) :: Iona.Source.t
  def source(criteria) when is_list(criteria) do
    %Iona.Source{path: Keyword.get(criteria, :path, nil),
                 include: Keyword.get(criteria, :include, [])}
  end

  @type supported_format_t :: atom
  @type tex_t :: iodata
  @type eex_tex_t :: binary
  @type executable_t :: binary

  @type processing_opts :: [
    {:preprocess, [executable_t]},
    {:processor, executable_t}
  ]

  @doc """
  Generate a formatted document as a string.

  Without processing options:

  ```
  {:ok, pdf_string} = Iona.source(path: "/path/to/document.tex")
  |> Iona.to(:pdf)
  ```

  With processing options:

  ```
  {:ok, pdf_string} = Iona.source(path: "/path/to/document.tex")
  |> Iona.to(:pdf, processor: "xetex")
  ```
  """
  @spec to(input :: Iona.Input.t,
           format :: supported_format_t,
           opts :: processing_opts) :: {:ok, binary} | {:error, binary}
  def to(input, format, opts \\ []) do
    case input |> Iona.Processing.process(format, opts) do
      {:ok, document} -> document |> Iona.Document.read
      other -> other
    end
  end

  @doc """
  The same as `to/3`, but raises `Iona.ProcessingError` if it fails.
  Returns the document content otherwise.

  ```
  Iona.source(path: "/path/to/document.tex")
  |> Iona.to!(:pdf)
  |> MyModule.do_something_with_pdf_string
  ```

  If writing to a file, see `write/3` and `write/4`, as they are both
  shorter to type and have better performance characteristics.
  """
  @spec to!(input :: Iona.Input.t,
            format :: supported_format_t,
            opts :: processing_opts) :: binary
  def to!(input, format, opts \\ []) do
    case to(input, format, opts) do
      {:ok, result} -> result
      {:error, err} -> raise Iona.Processing.ProcessingError, message: err
    end
  end

  @doc """
  Generate a formatted document to a file path.

  Without processing options:

  ```
  :ok = Iona.source(path: "/path/to/document.tex")
  |> Iona.write("/path/to/document.pdf")
  ```

  With processing options:

  ```
  :ok = Iona.source(path: "/path/to/document.tex")
  |> Iona.write("/path/to/document.pdf",
  processor: "xetex")
  ```
  """
  @spec write(input :: Iona.Input.t, path :: Path.t, opts :: processing_opts) :: :ok | {:error, term}
  def write(input, path, opts \\ []) do
    result = input |> Iona.Processing.process(path |> Iona.Processing.to_format, opts)
    case result do
      {:ok, document} -> Iona.Document.write(document, path)
      other -> other
    end
  end

  @doc """
  The same as `write/3` but raises `Iona.ProcessingError if it fails.

  Without processing options:

  ```
  Iona.source(path: "/path/to/document.tex")
  |> Iona.write!("/path/to/document.pdf")
  ```

  With processing options:

  ```
  Iona.source(path: "/path/to/document.tex")
  |> Iona.write!("/path/to/document.pdf", processor: "xetex")
  ```
  """
  @spec write!(input :: Iona.Input.t, path :: Path.t, opts :: processing_opts) :: :ok | no_return
  def write!(input, path, opts \\ []) do
    case write(input, path, opts) do
      :ok -> :ok
      {:error, err} -> raise Iona.Processing.ProcessingError, message: err
    end
  end

end
