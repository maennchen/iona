defmodule Iona.Helper do

  defmodule MissingHelperError do
    defexception [:message]
    def exception(name) do
      %__MODULE__{message: "Unknown helper: #{name}"}
    end
  end

  defmacro __using__(_opts) do
    quote do
      @helpers []
      @before_compile Iona.Helper
      import Iona.Helper, only: :macros
    end
  end

  def run(name, args) do
    arity = args |> length
    helper = helper_modules |> Enum.find fn mod ->
      Keyword.get(mod.__iona__(:helpers), name, nil) == arity
    end
    if helper do
      apply(helper, name, args)
    else
      raise MissingHelperError, "#{name}/#{arity} from #{helper_modules |> inspect}"
    end
  end

  def helper_modules do
    Application.get_env(:iona, :helpers, [])
  end

  @doc false
  defmacro __before_compile__(_) do
    quote do
      def __iona__(:helpers) do
        @helpers
      end
    end
  end

end
