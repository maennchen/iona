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
    "pdflatex" => @nonstopmode,
    "xelatex" => @nonstopmode
  }

  @spec to_format(path :: Path.t()) :: Iona.supported_format_t() | no_return
  def to_format(path) do
    format = path |> parse_format

    if supported_format?(format) do
      format
    else
      raise UnsupportedFormatError, message: format |> to_string
    end
  end

  @spec supported_format?(format :: Iona.supported_format_t()) :: boolean
  defp supported_format?(format) do
    Enum.member?(supported_formats(), format)
  end

  @spec parse_format(path :: Path.t()) :: nil | atom
  defp parse_format(path) do
    case Path.extname(path) do
      "" -> nil
      ext -> ext |> String.replace(~r/^\./, "") |> String.to_atom()
    end
  end

  @spec supported_formats :: [Iona.supported_format_t()]
  defp supported_formats do
    Iona.Config.processors() |> Keyword.keys()
  end

  @spec process(
          input :: Iona.Input.t(),
          format :: Iona.supported_format_t(),
          opts :: Iona.processing_opts()
        ) :: {:ok, Iona.Document.t()} | {:error, binary}
  def process(input, format, opts \\ []) do
    if Iona.Input.path?(input) do
      input |> process_path(format, opts)
    else
      input |> process_content(format, opts)
    end
  end

  @spec process_content(
          input :: Iona.Input,
          format :: Iona.supported_format_t(),
          opts :: Iona.processing_opts()
        ) :: {:ok, Iona.Document.t()} | {:error, binary}
  def process_content(input, format, opts) do
    with_temp(fn directory ->
      path = Path.join(directory, "document.tex")

      case File.write(path, input |> Iona.Input.content()) do
        :ok -> do_process(input, format, opts, path)
        _ -> {:error, "Could not write to temporary file at path: #{path}"}
      end
    end)
  end

  @spec process_path(
          input :: Iona.Input,
          format :: Iona.supported_format_t(),
          opts :: Iona.processing_opts()
        ) :: {:ok, Iona.Document.t()} | {:error, binary}
  def process_path(input, format, opts) do
    with_temp(fn directory ->
      input_path = input |> Iona.Input.path()
      path = Path.join(directory, Path.basename(input_path))

      case File.cp(input_path, path) do
        :ok ->
          do_process(input, format, opts, path)

        _ ->
          {:error,
           "Could not copy source file at path #{input_path} to temporary file at path: #{path}"}
      end
    end)
  end

  @spec do_process(
          input :: Iona.Input,
          format :: Iona.supported_format_t(),
          opts :: Iona.processing_opts(),
          path :: Path.t()
        ) :: {:ok, Iona.Document.t()} | {:prepared, Path.t()} | {:error, binary}
  defp do_process(input, format, opts, path) do
    processor = Keyword.get(opts, :processor, Keyword.get(Iona.Config.processors(), format, nil))

    if processor do
      ext = Path.extname(path)
      {:ok, regex} = Regex.compile("\\#{ext}$")
      output_path = String.replace(path, regex, ".#{format}")
      basename = Path.basename(path, ext)
      dirname = Path.dirname(path)
      preprocessors = Keyword.get(opts, :preprocess, Iona.Config.preprocess())

      case copy_includes(dirname, Iona.Input.included_files(input)) do
        :ok ->
          if opts[:prepare] do
            File.cp_r(dirname, opts[:prepare])

            commands =
              for command <- preprocessors ++ [processor], is_binary(command) do
                command <> " " <> basename
              end

            {:prepared, opts[:prepare], commands}
          else
            case preprocess(Path.basename(path), dirname, preprocessors) do
              :ok ->
                case Porcelain.exec(
                       processor,
                       executable_default_args(processor) ++ [basename],
                       dir: dirname,
                       out: :string
                     ) do
                  %{status: 0} -> {:ok, %Iona.Document{format: format, output_path: output_path}}
                  {:error, err} -> {:error, "Processing failed with output: #{err}"}
                end

              err ->
                err
            end
          end

        other ->
          other
      end
    else
      {:error, "Could not find processor for format: #{format}"}
    end
  end

  @spec preprocess(filename :: binary, dir :: Path.t(), preprocessors :: [Iona.executable_t()]) ::
          :ok | {:error, binary}
  defp preprocess(_filename, _dir, []), do: :ok

  defp preprocess(filename, dir, [preprocessor | remaining]) when is_binary(preprocessor) do
    basename = Path.basename(filename, Path.extname(filename))

    case Porcelain.exec(
           preprocessor,
           executable_default_args(preprocessor) ++ [basename],
           dir: dir,
           out: :string
         ) do
      %{status: 0} -> preprocess(filename, dir, remaining)
      {:error, err} -> {:error, "Preprocessing with #{preprocessor} failed with output: #{err}"}
    end
  end

  defp preprocess(filename, dir, [{:shell, command} | remaining]) do
    case Porcelain.shell(command, dir: dir, out: :string) do
      %{status: 0} ->
        preprocess(filename, dir, remaining)

      {:error, err} ->
        {:error, "Preprocessing with command `#{command}` failed with output: #{err}"}
    end
  end

  defp preprocess(filename, dir, [preprocessor | remaining]) when is_function(preprocessor) do
    case preprocessor.(dir, filename) do
      :ok -> preprocess(filename, dir, remaining)
      {:shell, _command} = shell -> preprocess(filename, dir, [shell | remaining])
      {:error, _} = failure -> failure
    end
  end

  @spec copy_includes(directory :: Path.t(), [Path.t()]) :: :ok | {:error, binary}
  defp copy_includes(_directory, []), do: :ok

  defp copy_includes(directory, [include | remaining]) do
    case File.cp_r(include, Path.join(directory, Path.basename(include))) do
      {:ok, _} -> copy_includes(directory, remaining)
      _ -> {:error, "Could not copy included file: #{include}"}
    end
  end

  @spec with_temp(fun :: (Path.t() -> any)) :: any
  defp with_temp(fun) do
    case Briefly.create(prefix: "iona", directory: true) do
      {:ok, path} -> fun.(path)
      _ -> {:error, "Could not create temporary location"}
    end
  end

  @spec executable_default_args(name :: Iona.executable_t()) :: [binary]
  defp executable_default_args(name) do
    Map.get(@executable_default_args, name, [])
    |> List.wrap()
  end
end
