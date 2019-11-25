# Taken in part from the Phoenix HTML project,
# https://github.com/phoenixframework/phoenix_html
defprotocol Iona.Template.Safe do
  @moduledoc """
  Defines the LaTex safe protocol.

  In order to promote LaTex safety, Phoenix templates
  do not use `Kernel.to_string/1` to convert data types to
  strings in templates. Instead, Phoenix uses this
  protocol which must be implemented by data structures
  and guarantee that a LaTex safe representation is returned.

  Furthermore, this protocol relies on iodata, which provides
  better performance when sending or streaming data to the client.
  """

  def to_iodata(data)
end

defimpl Iona.Template.Safe, for: Atom do
  def to_iodata(nil), do: ""
  def to_iodata(atom), do: Iona.Template.Helper.escape_to_iodata(Atom.to_string(atom))
end

defimpl Iona.Template.Safe, for: BitString do
  defdelegate to_iodata(data), to: Iona.Template.Helper, as: :escape
end

defimpl Iona.Template.Safe, for: Time do
  defdelegate to_iodata(data), to: Time, as: :to_string
end

defimpl Iona.Template.Safe, for: Date do
  defdelegate to_iodata(data), to: Date, as: :to_string
end

defimpl Iona.Template.Safe, for: NaiveDateTime do
  defdelegate to_iodata(data), to: NaiveDateTime, as: :to_string
end

defimpl Iona.Template.Safe, for: DateTime do
  def to_iodata(data) do
    # Call escape in case someone can inject reserved
    # characters in the timezone or its abbreviation
    Iona.Template.Helper.escape_to_iodata(DateTime.to_string(data))
  end
end

defimpl Iona.Template.Safe, for: List do
  def to_iodata([h | t]) do
    [to_iodata(h) | to_iodata(t)]
  end

  def to_iodata([]) do
    []
  end

  def to_iodata(h) when is_integer(h) and h <= 255 do
    Iona.Template.Helper.escape(to_string([h]))
  end

  def to_iodata(h) when is_integer(h) do
    raise ArgumentError,
          "lists in Iona.Template templates only support iodata, and not chardata. Integers may only represent bytes. " <>
            "It's likely you meant to pass a string with double quotes instead of a char list with single quotes."
  end

  def to_iodata(h) when is_binary(h) do
    Iona.Template.Helper.escape_to_iodata(h)
  end

  def to_iodata({:safe, data}) do
    data
  end

  def to_iodata(other) do
    raise ArgumentError,
          "lists in Iona.Template and templates may only contain integers representing bytes, binaries or other lists, " <>
            "got invalid entry: #{inspect(other)}"
  end
end

defimpl Iona.Template.Safe, for: Integer do
  def to_iodata(data), do: Integer.to_string(data)
end

defimpl Iona.Template.Safe, for: Float do
  def to_iodata(data) do
    IO.iodata_to_binary(:io_lib_format.fwrite_g(data))
  end
end

defimpl Iona.Template.Safe, for: Tuple do
  def to_iodata({:safe, data}), do: data
  def to_iodata(value), do: raise(Protocol.UndefinedError, protocol: @protocol, value: value)
end
