defmodule Iona.Template do

  @moduledoc false

  defmodule MissingTemplateError do
    defexception message: "No template file given"
  end

  @type template_opts :: [
    {:path, Path.t}
  ]

  @spec template(assigns :: Keyword.t, criteria :: Iota.Source.tex_t) :: Iona.Document.t
  def template(assigns, criteria) when is_binary(criteria) do
    EEx.eval_string(criteria, assigns: assigns)
    |> Iona.source
  end

  @spec template(assigns :: Keyword.t, criteria :: template_opts) :: Iona.Document.t
  def template(assigns, criteria) when is_list(criteria) do
    case Keyword.get(criteria, :path, nil) do
      nil -> raise MissingTemplateError
      path -> case File.read(path) do
                {:ok, content} -> template(assigns, content)
                _ -> raise MissingTemplateError, message: (path |> to_string)
              end
    end
  end

end
