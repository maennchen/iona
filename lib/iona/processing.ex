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

  @spec to_format(path :: Path.t()) :: Iona.supported_format_t()
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
      process_path(input, &do_process(input, format, opts, &1))
    else
      process_content(input, &do_process(input, format, opts, &1))
    end
  end

  @spec prepare(
          input :: Iona.Input.t(),
          output :: Path.t(),
          format :: Iona.supported_format_t(),
          opts :: Iona.processing_opts()
        ) :: {:ok, iodata} | {:error, binary}
  def prepare(input, output, format, opts \\ []) do
    if Iona.Input.path?(input) do
      process_path(input, &do_prepare(input, output, format, opts, &1))
    else
      process_content(input, &do_prepare(input, output, format, opts, &1))
    end
  end

  @spec process_content(input :: Iona.Input.t(), callback :: (path :: Path.t() -> any)) :: any
  defp process_content(input, callback) do
    with_temp(fn directory ->
      path = Path.join(directory, "document.tex")

      case File.write(path, input |> Iona.Input.content()) do
        :ok -> callback.(path)
        _ -> {:error, "Could not write to temporary file at path: #{path}"}
      end
    end)
  end

  @spec process_path(input :: Iona.Input.t(), callback :: (path :: Path.t() -> any)) :: any
  defp process_path(input, callback) do
    with_temp(fn directory ->
      input_path = input |> Iona.Input.path()
      path = Path.join(directory, Path.basename(input_path))

      case File.cp(input_path, path) do
        :ok ->
          callback.(path)

        _ ->
          {:error,
           "Could not copy source file at path #{input_path} to temporary file at path: #{path}"}
      end
    end)
  end

  @spec do_process(
          input :: Iona.Input.t(),
          format :: Iona.supported_format_t(),
          opts :: Iona.processing_opts(),
          path :: Path.t()
        ) :: {:ok, Iona.Document.t()} | {:prepared, Path.t(), String.t()} | {:error, binary}
  defp do_process(input, format, opts, path) do
    with <<processor::binary>> <-
           Keyword.get(opts, :processor, Keyword.get(Iona.Config.processors(), format, nil)),
         ext <- Path.extname(path),
         {:ok, regex} <- Regex.compile("\\#{ext}$"),
         output_path <- String.replace(path, regex, ".#{format}"),
         basename <- Path.basename(path, ext),
         dirname <- Path.dirname(path),
         preprocessors <- Keyword.get(opts, :preprocess, Iona.Config.preprocess()),
         :ok <- copy_includes(dirname, Iona.Input.included_files(input)),
         :ok <- preprocess(Path.basename(path), dirname, preprocessors, opts),
         <<processor_path::binary>> <- System.find_executable(processor),
         {_output, 0} <-
           Enum.reduce_while(1..Keyword.get(opts, :compilation_passes, 1), {"", 0}, fn _i, _acc ->
             case System.cmd(
                    processor_path,
                    Enum.concat([
                      executable_default_args(processor),
                      Keyword.get(opts, :processor_extra_args, []),
                      [basename]
                    ]),
                    stderr_to_stdout: true,
                    cd: dirname,
                    env: Keyword.get(opts, :processor_env, [])
                  ) do
               {_output, 0} = result -> {:cont, result}
               {_output, status} = result when status > 0 -> {:halt, result}
             end
           end) do
      {:ok, %Iona.Document{format: format, output_path: output_path}}
    else
      {:error, error} ->
        {:error, error}

      {output, status} when is_binary(output) and status > 0 ->
        {:error, "Error executing processor with status code #{status} and output #{output}"}

      nil ->
        {:error, "Could not find processor for format: #{format}"}
    end
  end

  @spec do_prepare(
          input :: Iona.Input.t(),
          output :: Path.t(),
          format :: Iona.supported_format_t(),
          opts :: Iona.processing_opts(),
          path :: Path.t()
        ) :: {:ok, Iona.Document.t()} | {:ok, iodata} | {:error, binary}
  defp do_prepare(input, output, format, opts, path) do
    with processor when not is_nil(processor) <-
           Keyword.get(opts, :processor, Keyword.get(Iona.Config.processors(), format, nil)),
         ext <- Path.extname(path),
         basename <- Path.basename(path, ext),
         dirname <- Path.dirname(path),
         preprocessors <- Keyword.get(opts, :preprocess, Iona.Config.preprocess()),
         :ok <- copy_includes(dirname, Iona.Input.included_files(input)),
         {:ok, _} <- File.cp_r(dirname, output) do
      commands =
        for command <- preprocessors ++ [processor], is_binary(command) do
          command <> " " <> basename
        end

      {:ok, commands}
    else
      {:error, error} ->
        {:error, error}

      {:error, _, error} ->
        {:error, error}

      nil ->
        {:error, "Could not find processor for format: #{format}"}
    end
  end

  @spec preprocess(
          filename :: binary,
          dir :: Path.t(),
          preprocessors :: [Iona.executable_t()],
          opts :: Iona.processing_opts()
        ) ::
          :ok | {:error, binary}
  defp preprocess(_filename, _dir, [], _opts), do: :ok

  defp preprocess(filename, dir, [preprocessor | remaining], opts) when is_binary(preprocessor) do
    basename = Path.basename(filename, Path.extname(filename))

    <<preprocessor_path::binary>> = System.find_executable(preprocessor)

    case System.cmd(
           preprocessor_path,
           Enum.concat([
             executable_default_args(preprocessor),
             Keyword.get(opts, :preprocessor_extra_args, []),
             [basename]
           ]),
           cd: dir,
           stderr_to_stdout: true,
           env: Keyword.get(opts, :preprocessor_env, [])
         ) do
      {_output, 0} ->
        preprocess(filename, dir, remaining, opts)

      {output, status} when is_binary(output) and status > 0 ->
        {:error,
         "Preprocessing with command `#{preprocessor}` failed with status code #{status} output: #{output}"}
    end
  end

  defp preprocess(filename, dir, [{:shell, command} | remaining], opts) do
    case System.cmd("/bin/sh", ["-c", command],
           cd: dir,
           stderr_to_stdout: true,
           env: Keyword.get(opts, :preprocessor_env, [])
         ) do
      {_output, 0} ->
        preprocess(filename, dir, remaining, opts)

      {output, status} when is_binary(output) and status > 0 ->
        {:error,
         "Preprocessing with command `#{command}` failed with status code #{status} output: #{output}"}
    end
  end

  defp preprocess(filename, dir, [preprocessor | remaining], opts)
       when is_function(preprocessor) do
    case preprocessor.(dir, filename) do
      :ok -> preprocess(filename, dir, remaining, opts)
      {:shell, _command} = shell -> preprocess(filename, dir, [shell | remaining], opts)
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
