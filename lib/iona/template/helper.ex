defmodule Iona.Template.Helper do

  @replace [
    {~r/([{}])/,    ~S(\\\\\1)},
    {~r/\\/,        ~S(\textbackslash{})},
    {~r/\^/,        ~S(\textasciicircum{})},
    {~r/~/,         ~S(\textasciitilde{})},
    {~r/\|/,        ~S(\textbar{})},
    {~r/\</,        ~S(\textless{})},
    {~r/\>/,        ~S(\textgreater{})},
    {~r/([_$&%\#])/, ~S(\\\\\1)}]

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
