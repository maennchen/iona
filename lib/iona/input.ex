defprotocol Iona.Input do

  @opaque t :: any

  def path?(input)

  def path(input)
  def content(input)

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
