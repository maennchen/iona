defmodule Test.Iona.Helper do
  use ExUnit.Case

  test "escape" do
    assert Iona.Template.Helper.escape("this | that") == ~S(this \textbar{} that)
  end

end
