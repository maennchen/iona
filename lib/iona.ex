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
  defdelegate template(assigns, criteria), to: Iona.Template


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
  defdelegate source(criteria), to: Iona.Source

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
  defdelegate [to(criteria, format, opts),
               to(criteria, format)], to: Iona.Processing

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
  defdelegate [to!(criteria, format, opts),
               to!(criteria, format)], to: Iona.Processing

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
  defdelegate [write(doc, path, opts),
               write(doc, path)], to: Iona.Processing

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
  defdelegate [write!(doc, path, opts),
               write!(doc, path)], to: Iona.Processing

end
