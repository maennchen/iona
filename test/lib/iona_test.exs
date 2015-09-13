defmodule Test.Iona do
  use ExUnit.Case, async: true

  @bad "test/fixtures/does/not/exist.tex"
  @simple "test/fixtures/simple.tex"
  @simple_content File.read!(@simple)
  @cite "test/fixtures/cite.tex"
  @citebib "test/fixtures/cite.bib"
  @items_template "test/fixtures/items.tex.eex"
  @add_two_template "test/fixtures/add-two.tex.eex"
  @raw_template "test/fixtures/raw.tex.eex"

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

  test "templates are escaped by default" do
    content = [name: "Escaped", items: ~W(\foo \bar \baz)]
    |> Iona.template(path: @items_template)
    |> read_content
    assert String.contains?(content, ~S(\textbackslash{}foo))
    assert String.contains?(content, ~S(\textbackslash{}bar))
    assert String.contains?(content, ~S(\textbackslash{}baz))
  end

  test "templates can accept non-strings" do
    content = [name: "Integers", items: [1, 2, 3]]
    |> Iona.template(path: @items_template)
    |> read_content
    assert String.contains?(content, ~S(\item 1))
    assert String.contains?(content, ~S(\item 2))
    assert String.contains?(content, ~S(\item 3))
  end

  test "template can provide raw values" do
    content = [name: "Escaped", items: [{:safe, ~S(\foo)},
                                         {:safe, ~S(\bar)},
                                         {:safe, ~S(\baz)}]]
    |> Iona.template(path: @items_template)
    |> read_content
    assert String.contains?(content, ~S(\foo))
    assert String.contains?(content, ~S(\bar))
    assert String.contains?(content, ~S(\baz))
  end

  test "template can accept additional helpers" do
    content = [name: "Add Two", items: [1, 2, 3]]
    |> Iona.template(path: @add_two_template, helpers: [Test.Iona.Template.Helpers.AddTwo])
    |> read_content
    assert String.contains?(content, ~S(\item 3))
    assert String.contains?(content, ~S(\item 4))
    assert String.contains?(content, ~S(\item 5))
  end

  test "template can insert safe content" do
    content = [name: ~S({\bf Safe})]
    |> Iona.template(path: @raw_template)
    |> read_content
    assert String.contains?(content, ~S(\item[Name] {\bf Safe}))
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

  defp read_content(%{content: content}), do: content |> IO.iodata_to_binary
end
