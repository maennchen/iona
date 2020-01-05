defmodule Iona do
  @moduledoc File.read!("#{__DIR__}/../README.md")

  @type template_opts :: [
          {:path, Path.t()},
          {:include, [Path.t()]},
          {:helpers, [atom]}
        ]
  @type source_opts :: [
          {:path, Path.t()},
          {:include, [Path.t()]}
        ]

  @type supported_format_t :: atom
  @type tex_t :: iodata
  @type eex_tex_t :: binary
  @type executable_t :: binary

  @type processing_opts :: [
          {:preprocess, [executable_t]}
          | {:processor, executable_t}
          | {:processor_env, map}
          | {:preprocessor_env, map}
          | {:compilation_passes, non_neg_integer}
        ]

  @doc """
  Fill in a template with assignments, with TeX escaping support

  ```
  {:ok, template} = [title: "An Article", author: "Bruce Williams"]
  |> Iona.template(path: "/path/to/article.tex")

  Iona.write(template, "/path/to/article.pdf")
  ```
  """
  @spec template(assigns :: Keyword.t() | map, criteria :: eex_tex_t) ::
          {:ok, Iona.Template.t()} | {:error, term}
  def template(assigns, criteria) when is_binary(criteria) do
    assigns |> Iona.Template.fill(%Iona.Template{body: criteria})
  end

  @spec template(assigns :: Keyword.t() | map, criteria :: template_opts) ::
          {:ok, Iona.Template.t()} | {:error, term}
  def template(assigns, criteria) when is_list(criteria) do
    template = %Iona.Template{
      body_path: Keyword.get(criteria, :path),
      include: Keyword.get(criteria, :include, []),
      helpers: Keyword.get(criteria, :helpers, [])
    }

    assigns |> Iona.Template.fill(template)
  end

  @doc """
  The same as `template/2`, but raises `Iona.ProcessingError` if it fails.
  Returns the template otherwise.

  ```
  [title: "An Article", author: "Bruce Williams"]
  |> Iona.template!(path: "/path/to/article.tex")
  |> Iona.write("/path/to/article.pdf")
  ```
  """
  @spec template!(assigns :: Keyword.t() | map, criteria :: eex_tex_t | template_opts) ::
          Iona.Template.t()
  def template!(assigns, criteria) do
    case template(assigns, criteria) do
      {:ok, result} -> result
      {:error, err} -> raise Iona.Processing.ProcessingError, message: err
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
  @spec source(criteria :: binary) :: Iona.Source.t()
  def source(criteria) when is_binary(criteria) do
    %Iona.Source{content: criteria}
  end

  @spec source(criteria :: source_opts) :: Iona.Source.t()
  def source(criteria) when is_list(criteria) do
    %Iona.Source{
      path: Keyword.get(criteria, :path, nil),
      include: Keyword.get(criteria, :include, [])
    }
  end

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
  @spec to(
          input :: Iona.Input.t(),
          format :: supported_format_t,
          opts :: processing_opts
        ) :: {:ok, binary} | {:error, binary}
  def to(input, format, opts \\ []) do
    case input |> Iona.Processing.process(format, opts) do
      {:ok, document} -> document |> Iona.Document.read()
      {:error, error} -> {:error, error}
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
  @spec to!(
          input :: Iona.Input.t(),
          format :: supported_format_t,
          opts :: processing_opts
        ) :: binary
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
  @spec write(input :: Iona.Input.t(), path :: Path.t(), opts :: processing_opts) ::
          :ok | {:error, term}
  def write(input, path, opts \\ []) do
    input
    |> Iona.Processing.process(path |> Iona.Processing.to_format(), opts)
    |> case do
      {:ok, document} ->
        Iona.Document.write(document, path)

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  The same as `write/3` but raises `Iona.ProcessingError` if it fails.

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
  @spec write!(input :: Iona.Input.t(), path :: Path.t(), opts :: processing_opts) :: :ok
  def write!(input, path, opts \\ []) do
    case write(input, path, opts) do
      :ok -> :ok
      {:error, err} -> raise Iona.Processing.ProcessingError, message: err
    end
  end

  @doc """
  Generate a directory with a build script that can be run to finalize the build.

  ## Examples

      iex> Iona.source(path: "academic.tex")
      iex> |> Iona.prepare!("/path/to/build/directory", :pdf, preprocess: ~w(latex bibtex latex))
      :ok

  """
  @spec prepare(
          input :: Iona.Input.t(),
          output :: Path.t(),
          format :: Iona.supported_format_t(),
          opts :: processing_opts
        ) :: :ok | {:error, term}
  def prepare(input, output, format, opts \\ []) do
    with {:ok, commands} <- Iona.Processing.prepare(input, output, format, opts),
         :ok <- write_build_script(output, commands) do
      :ok
    else
      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  The same as `prepare/4` but raises `Iona.ProcessingError` if it fails.
  """
  @spec prepare!(
          input :: Iona.Input.t(),
          output :: Path.t(),
          format :: Iona.supported_format_t(),
          opts :: processing_opts
        ) :: :ok
  def prepare!(input, output, format, opts \\ []) do
    case prepare(input, output, format, opts) do
      :ok -> :ok
      {:error, err} -> raise Iona.Processing.ProcessingError, message: err
    end
  end

  @spec write_build_script(Path.t(), [String.t()]) :: :ok | {:error, File.posix()}
  defp write_build_script(directory, commands) do
    script = Path.join(directory, "build.sh")

    with :ok <- File.write(script, script_content(commands)),
         :ok <- File.chmod(script, 0o755) do
      :ok
    else
      {:error, error} ->
        {:error, error}
    end
  end

  @spec script_content([String.t()]) :: iodata
  defp script_content(commands) do
    [
      "#!/bin/sh\n",
      Enum.intersperse(commands, " && \\\n")
    ]
  end
end
