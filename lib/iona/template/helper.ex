defmodule Iona.Template.Helper do
  @moduledoc """
  Provides basic template helper functions.

  The most important function is `escape`, which is automatically applied to any
  value in a `<%= %>` concat tag.
  """

  @replace [
    {~r/([{}])/,    ~S(\\\\\1)},
    {~r/\\/,        ~S(\textbackslash{})},
    {~r/\^/,        ~S(\textasciicircum{})},
    {~r/~/,         ~S(\textasciitilde{})},
    {~r/\|/,        ~S(\textbar{})},
    {~r/\</,        ~S(\textless{})},
    {~r/\>/,        ~S(\textgreater{})},
    {~r/([_$&%\#])/, ~S(\\\\\1)}]

  @doc """
  Escape raw LaTeX commands and reserved characters, to include:

  * Brackets and braces
  * Backslashes
  * Carets
  * Tildes
  * Pipes
  * More! (See the `@replace` module attribute)
  """
  def escape({:safe, text}) do
    text
  end
  def escape(text) when is_binary(text) do
    @replace
    |> Enum.reduce text, fn ({pattern, replacement}, memo) ->
      memo |> String.replace(pattern, replacement)
    end
  end

end
