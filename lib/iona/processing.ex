defmodule Iona.Processing do

  @moduledoc false

  defmodule UnsupportedFormatError do
    defexception message: "No processor defined for format"
  end

  defmodule ProcessingError do
    defexception message: "Could not process the document"
  end

  @nonstopmode "-interaction=nonstopmode"
  @executable_default_args %{
    "latex" => @nonstopmode,
    "pdflatex" => @nonstopmode
  }

  @spec to_format(path :: Path.t) :: Iona.supported_format | no_return
  def to_format(path) do
    format = path |> parse_format
    if supported_format?(format) do
      format
    else
      raise UnsupportedFormat, message: (format |> to_string)
    end
  end

  @spec supported_format?(format :: Iona.supported_format) :: boolean
  defp supported_format?(format) do
    Enum.member?(supported_formats, format)
  end

  @spec parse_format(path :: Path.t) :: nil | atom
  defp parse_format(path) do
    case Path.extname(path) do
      "" -> nil
      ext -> ext |> String.replace(~r/^\./, "") |> String.to_atom
    end
  end

  @spec supported_formats :: [Iona.supported_format]
  defp supported_formats do
    Iona.Config.processors |> Keyword.keys
  end

  @spec process(input :: Iona.Input.t, format :: Iona.supported_format, opts :: Iona.processing_opts) :: {:ok, Iona.Document.t} | {:error, binary}
  def process(input, format, opts \\ []) do
    if Iona.Input.path?(input) do
      input |> process_path(format, opts)
    else
      input |> process_content(format, opts)
    end
  end

  @spec process_content(input :: Iona.Input, format :: Iona.supported_format, opts :: Iona.processing_opts) :: {:ok, Iona.Document.t} | {:error, binary}
  def process_content(input, format, opts) do
    with_temp fn directory ->
      path = Path.join(directory, "document.tex")
      case File.write(path, input |> Iona.Input.content) do
        :ok -> do_process(input, format, opts, path)
        _ -> {:error, "Could not write to temporary file at path: #{path}"}
      end
    end
  end

  @spec process_content(input :: Iona.Input, format :: Iona.supported_format, opts :: Iona.processing_opts) :: {:ok, Iona.Document.t} | {:error, binary}
  def process_path(input, format, opts) do
    with_temp fn directory ->
      input_path = input |> Iona.Input.path
      path = Path.join(directory, Path.basename(input_path))
      case File.cp(input_path, path) do
        :ok -> do_process(input, format, opts, path)
        _ -> {:error, "Could not copy source file at path #{input_path} to temporary file at path: #{path}"}
      end
    end
  end

  @spec do_process(input :: Iona.Input, format :: Iona.supported_format, opts :: Iona.processing_opts, path :: Path.t) :: {:ok, Iona.Document.t} | {:error, binary}
  defp do_process(input, format, opts, path) do
    processor = Keyword.get(opts, :processor, Keyword.get(Iona.Config.processors, format, nil))
    if processor do
      output_path = String.replace(path, ~r/\.tex$/, ".#{format}")
      basename = Path.basename(path, ".tex")
      dirname = Path.dirname(path)
      preprocessors = Keyword.get(opts, :preprocess, Iona.Config.preprocess)
      case copy_includes(dirname, Iona.Input.included_files(input)) do
        :ok ->
          case preprocess(basename, dirname, preprocessors) do
            :ok ->
              case Porcelain.exec(processor,
                                  executable_default_args(processor) ++ [basename],
                                  dir: dirname, out: :string) do
                %{status: 0} -> {:ok, %Iona.Document{format: format, output_path: output_path}}
                failure -> {:error, "Processing failed with output: #{failure.out}"}
              end
            err -> err
          end
        other -> other
      end
    else
      {:error, "Could not find processor for format: #{format}"}
    end
  end

  @spec preprocess(name :: binary, dir :: Path.t, preprocessors :: [Iona.executable]) :: :ok | {:error, binary}
  defp preprocess(_name, _dir, []), do: :ok
  defp preprocess(name, dir, [preprocessor|remaining]) do
    case Porcelain.exec(preprocessor,
                        executable_default_args(preprocessor) ++ [name],
                        dir: dir, out: :string) do
      %{status: 0} -> preprocess(name, dir, remaining)
      failure -> {:error, "Preprocessing with #{preprocessor} failed with output: #{failure.out}"}
    end
  end

  @spec copy_includes(directory :: Path.t, [Path.t]) :: :ok | {:error, binary}
  defp copy_includes(_directory, []), do: :ok
  defp copy_includes(directory, [include|remaining]) do
    case File.cp(include, Path.join(directory, Path.basename(include))) do
      :ok -> copy_includes(directory, remaining)
       _ -> {:error, "Could not copy included file: #{include}"}
    end
  end

  @spec with_temp(fun :: (Path.t -> any)) :: any
  defp with_temp(fun) do
    case Briefly.create(prefix: "iona", directory: true) do
      {:ok, path} -> fun.(path)
      _ -> {:error, "Could not create temporary location"}
    end
  end

  @spec executable_default_args(name :: Iona.executable) :: [binary]
  defp executable_default_args(name) do
    Map.get(@executable_default_args, name, [])
    |> List.wrap
  end

end
