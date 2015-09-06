defmodule Test.Iona do
  use ExUnit.Case, async: true

  @bad "test/fixtures/does/not/exist.tex"
  @simple "test/fixtures/simple.tex"
  @simple_content File.read!(@simple)
  @cite "test/fixtures/cite.tex"
  @citebib "test/fixtures/cite.bib"
  @items_template "test/fixtures/items.tex.eex"

  test "creates an input from raw TeX" do
    assert Iona.source(@simple_content) |> Iona.Input.content == @simple_content
  end

  test "creates an input from a path" do
    assert Iona.source(path: @simple) |> Iona.Input.path == @simple
  end

  test "creates an input from a bad path" do
    assert Iona.source(path: @bad) |> Iona.Input.path == @bad
  end

  test "to returns a tuple with a PDF binary from content" do
    {:ok, out} = @simple_content |> Iona.source |> Iona.to(:pdf)
    assert String.starts_with?(out, "%PDF")
  end

  test "template simple interpolation" do
    out = [name: "Squash", items: ~w(Acorn Summer Spaghetti)]
    |> Iona.template(path: @items_template)
    |> Iona.to!(:pdf)
    assert String.starts_with?(out, "%PDF")
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
    assert_raise Iona.Processing.ProcessingError, fn ->
      Iona.source(path: @bad) |> Iona.to!(:pdf)
    end
  end

  test "write! generates a PDF" do
    path = Briefly.create!(prefix: "iona-test", extname: ".pdf")
    Iona.source(path: @simple)
    |> Iona.write!(path)
    assert String.starts_with?(File.read!(path), "%PDF")
  end

  test "write! generates a PDF with citations" do
    path = Briefly.create!(prefix: "iona-test", extname: ".pdf")
    Iona.source(path: @cite, include: [@citebib])
    |> Iona.write!(path, preprocess: ~w(latex bibtex latex))
    assert String.starts_with?(File.read!(path), "%PDF")
  end

end
