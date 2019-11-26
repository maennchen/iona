defmodule Test.Iona.Helper do
  use ExUnit.Case

  alias Iona.Template.Helper

  test "escape pipe" do
    assert Helper.escape("this | that") == ~S(this \textbar{} that)
  end

  test "escape braces" do
    assert Helper.escape("this {} that") == ~S(this \{\} that)
  end

  test "escape backslashes" do
    assert Helper.escape("this \\ that") == ~S(this \textbackslash{} that)
  end
end
