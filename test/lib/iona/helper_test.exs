defmodule Test.Iona.HelperTest do
  use ExUnit.Case, async: true

  defmodule Example do
    use Iona.Helper

    @helpers [example: 1, num: 1, eq: 1]

    def example(input) do
      "(eg, #{input})"
    end
    def num(input) when is_integer(input) do
      "##{input}"
    end
    def eq(input) do
      "==#{input}=="
    end
  end

  test "creates a function" do
    assert Iona.Helper.run(:example, ["foo"]) == "(eg, foo)"
    assert Iona.Helper.run(:num, [2]) == "#2"
    assert Iona.Helper.run(:eq, ["foo"]) == "==foo=="
  end

end
