defmodule Test.Iona.Helper do
  use ExUnit.Case

  test "escape pipe" do
    assert Iona.Template.Helper.escape("this | that") == ~S(this \textbar{} that)
  end

  test "escape braces" do
    assert Iona.Template.Helper.escape("this {} that") == ~S(this \{\} that)
  end

  test "escape backslashes" do
    assert Iona.Template.Helper.escape("this \\ that") == ~S(this \textbackslash{} that)
  end

end
