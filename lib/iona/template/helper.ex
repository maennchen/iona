defmodule Iona.Template.Helper do
  @moduledoc """
  Provides basic template helper functions.

  The most important function is `escape`, which is automatically applied to any
  value in a `<%= %>` concat tag.
  """

  @dialyzer {:no_improper_lists, to_iodata: 4}
  @dialyzer {:no_improper_lists, to_iodata: 5}

  escapes = [
    {?{, "\\{"},
    {?}, "\\}"},
    {?\\, "\\textbackslash{}"},
    {?#, "\\#"},
    {?$, "\\$"},
    {?%, "\\%"},
    {?&, "\\&"},
    {?^, "\\textasciicircum{}"},
    {?_, "\\_"},
    {?|, "\\textbar{}"},
    {?~, "\\textasciitilde{}"}
  ]

  @doc """
  Escape raw LaTeX commands and reserved characters, to include:

  * Angle brackets and curly braces
  * Backslashes
  * Carets
  * Tildes
  * Pipes
  * More! (See the `@replace` module attribute)
  """
  def escape(data) when is_binary(data) do
    IO.iodata_to_binary(escape_to_iodata(data))
  end

  def escape_to_iodata(data) do
    to_iodata(data, 0, data, [])
  end

  @doc """
  Mark text as a string to be inserted raw and unescaped
  """
  def raw(text), do: {:safe, text}

  for {match, insert} <- escapes do
    defp to_iodata(<<unquote(match), rest::bits>>, skip, original, acc) do
      to_iodata(rest, skip + 1, original, [acc | unquote(insert)])
    end
  end

  defp to_iodata(<<_char, rest::bits>>, skip, original, acc) do
    to_iodata(rest, skip, original, acc, 1)
  end

  defp to_iodata(<<>>, _skip, _original, acc) do
    acc
  end

  for {match, insert} <- escapes do
    defp to_iodata(<<unquote(match), rest::bits>>, skip, original, acc, len) do
      part = binary_part(original, skip, len)
      to_iodata(rest, skip + len + 1, original, [acc, part | unquote(insert)])
    end
  end

  defp to_iodata(<<_char, rest::bits>>, skip, original, acc, len) do
    to_iodata(rest, skip, original, acc, len + 1)
  end

  defp to_iodata(<<>>, 0, original, _acc, _len) do
    original
  end

  defp to_iodata(<<>>, skip, original, acc, len) do
    [acc | binary_part(original, skip, len)]
  end
end
