defprotocol Iona.Input do

  @opaque t :: any

  @spec path?(input :: t) :: boolean
  def path?(input)

  @spec path(input :: t) :: Path.t | nil
  def path(input)

  @spec content(input :: t) :: Iona.tex_t
  def content(input)

  @spec included_files(input :: t) :: [Path.t]
  def included_files(input)

end

defimpl Iona.Input, for: [Iona.Source, Iona.Template] do

  def path?(%{path: path}) when is_binary(path), do: true
  def path?(_), do: false

  def path(%{path: path}), do: path

  def content(%{content: content}), do: content

  def included_files(%{include: include}), do: include |> List.wrap
  def included_files(%{}), do: []

end
