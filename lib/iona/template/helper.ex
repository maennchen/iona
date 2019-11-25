defmodule Iona.Template.Helper do
  @moduledoc """
  Provides basic template helper functions.

  The most important function is `escape`, which is automatically applied to any
  value in a `<%= %>` concat tag.
  """

  @replace [
    {"{", "\\{"},
    {"}", "\\}"},
    {~r/\\(?![{}])/, "\\textbackslash{}"},
    {"#", "\\#"},
    {"$", "\\$"},
    {"%", "\\%"},
    {"&", "\\&"},
    {"^", "\\textasciicircum{}"},
    {"_", "\\_"},
    {"|", "\\textbar{}"},
    {"~", "\\textasciitilde{}"}
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
  def escape({:safe, text}) do
    text
  end

  def escape(text) when is_binary(text) do
    @replace
    |> Enum.reduce(text, fn {pattern, replacement}, memo ->
      memo |> String.replace(pattern, replacement)
    end)
  end

  def escape_to_iodata(text) do
    escape(text)
  end

  @doc """
  Mark text as a string to be inserted raw and unescaped
  """
  def raw(text), do: {:safe, text}
end
