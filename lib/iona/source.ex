defmodule Iona.Source do

  @moduledoc false

  @type tex_t :: binary

  @type source_opts :: [
    {:path, Path.t},
    {:include, [Path.t]}
  ]

  @spec source(criteria :: tex_t) :: Iona.Document.t
  def source(criteria) when is_binary(criteria) do
    %Iona.Document{source: criteria}
  end
  @spec source(criteria :: source_opts) :: Iona.Document.t
  def source(criteria) when is_list(criteria) do
    %Iona.Document{source_path: Keyword.get(criteria, :path, nil),
                   include: Keyword.get(criteria, :include, []) |> List.wrap}
  end

end
