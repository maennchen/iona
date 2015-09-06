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

  test "to returns a tuple with a PDF binary for a good path" do
    {:ok, out} = Iona.source(path: @simple) |> Iona.to(:pdf)
    assert String.starts_with?(out, "%PDF")
  end

  test "to! returns a PDF binary for a good path" do
    out = Iona.source(path: @simple) |> Iona.to!(:pdf)
    assert String.starts_with?(out, "%PDF")
  end

  test "to returns a tuple with an error for a bad path" do
    {:error, _} = Iona.source(path: @bad) |> Iona.to(:pdf)
  end

  test "to! raises an exception with a bad path" do
    assert_raise Iona.ProcessingError, fn ->
      Iona.source(path: @bad) |> Iona.to!(:pdf)
    end
  end

  test "write! generates a PDF" do
    path = Briefly.create!(prefix: "iona-test", extname: ".pdf")
    Iona.source(path: @simple)
    |> Iona.write!(path)
    assert String.starts_with?(File.read!(path), "%PDF")
  end

end
