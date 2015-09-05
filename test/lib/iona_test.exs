defmodule Test.Iona do
  use ExUnit.Case, async: true

  @bad "test/fixtures/does/not/exist.tex"
  @simple "test/fixtures/simple.tex"
  @simple_content File.read!(@simple)

  test "creates a source from content" do
    %{source: @simple_content} = Iona.source(@simple_content)
  end

  test "creates a source from a path" do
    %{source_path: @simple} = Iona.source(path: @simple)
  end

  test "creates a source from a bad path" do
    %{source_path: @bad} = Iona.source(path: @bad)
  end

  test "to returns a tuple with a document for a good path" do
    {:ok, doc} = Iona.source(path: @simple) |> Iona.to(:pdf)
    assert doc.source == @simple_content
  end

  test "to! returns a document for a good path" do
    doc = Iona.source(path: @simple) |> Iona.to!(:pdf)
    assert doc.source == @simple_content
  end

  test "to returns a tuple with an error for a bad path" do
    {:error, _} = Iona.source(path: @bad) |> Iona.to(:pdf)
  end

  test "to! raises an exception with a bad path" do
    assert_raise MatchError, fn ->
      Iona.source(path: @bad) |> Iona.to!(:pdf)
    end
  end

end
