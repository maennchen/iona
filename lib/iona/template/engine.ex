# Taken in part from the Phoenix HTML project,
# https://github.com/phoenixframework/phoenix_html
defmodule Iona.Template.Engine do

  @moduledoc false

  @behaviour EEx.Engine

  defdelegate escape(value), to: Iona.Template.Helper

  @impl true
  def init(_opts) do
    %{
      iodata: [],
      dynamic: [],
      vars_count: 0
    }
  end

  @impl true
  def handle_begin(state) do
    %{state | iodata: [], dynamic: []}
  end

  @impl true
  def handle_end(quoted) do
    handle_body(quoted)
  end

  @impl true
  def handle_body(state) do
    %{iodata: iodata, dynamic: dynamic} = state
    safe = {:safe, Enum.reverse(iodata)}
    {:__block__, [], Enum.reverse([safe | dynamic])}
  end

  @impl true
  def handle_text(state, text) do
    %{iodata: iodata} = state
    %{state | iodata: [text | iodata]}
  end

  @impl true
  def handle_expr(state, "=", ast) do
    line   = line_from_expr(ast)
    ast = traverse(ast)
    %{iodata: iodata, dynamic: dynamic, vars_count: vars_count} = state
    var = Macro.var(:"arg#{vars_count}", __MODULE__)
    ast = quote do: unquote(var) = unquote(to_safe(ast, line))
    %{state | dynamic: [ast | dynamic], iodata: [var | iodata], vars_count: vars_count + 1}
  end

  def handle_expr(state, "", ast) do
    ast = traverse(ast)
    %{dynamic: dynamic} = state
    %{state | dynamic: [ast | dynamic]}
  end

  def handle_expr(state, marker, ast) do
    EEx.Engine.handle_expr(state, marker, ast)
  end

  defp traverse(expr) do
    Macro.prewalk(expr, &handle_assign/1)
  end

  defp line_from_expr({_, meta, _}) when is_list(meta), do: Keyword.get(meta, :line)
  defp line_from_expr(_), do: nil

  # We can do the work at compile time
  defp to_safe(literal, _line) when is_binary(literal) or is_atom(literal) or is_number(literal) do
    to_iodata(literal)
  end

  # We can do the work at runtime
  defp to_safe(literal, line) when is_list(literal) do
    quote line: line, do: Iona.Template.Engine.to_iodata(unquote(literal))
  end

  # We need to check at runtime and we do so by
  # optimizing common cases.
  defp to_safe(expr, line) do
    # Keep stacktraces for protocol dispatch...
    fallback = quote line: line, do: Iona.Template.Engine.to_iodata(other)

    # However ignore them for the generated clauses to avoid warnings
    quote line: :keep do
      case unquote(expr) do
        {:safe, data} -> data
        bin when is_binary(bin) -> Iona.Template.Engine.escape(bin)
        other -> unquote(fallback)
      end
    end
  end

  defp handle_assign({:@, meta, [{name, _, atom}]}) when is_atom(name) and is_atom(atom) do
    quote line: meta[:line] || 0 do
      Iona.Template.Engine.fetch_assign(var!(assigns), unquote(name))
    end
  end
  defp handle_assign(arg), do: arg

  @doc false
  def fetch_assign(assigns, key) when is_map(assigns) do
    fetch_assign(Map.to_list(assigns), key)
  end
  def fetch_assign(assigns, key) do
    case Keyword.fetch(assigns, key) do
      :error ->
        raise ArgumentError, message: """
        assign @#{key} not available in eex template. Available assigns: #{inspect Keyword.keys(assigns)}
        """
      {:ok, val} -> val
    end
  end

  def to_iodata({:safe, str}) do
    str |> to_string
  end
  def to_iodata([h|t]) do
    [to_iodata(h)|to_iodata(t)]
  end
  def to_iodata([]) do
    []
  end
  def to_iodata(value) do
    value |> to_string |> escape
  end

end
