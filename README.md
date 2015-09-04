Iona
====
[![Build Status](https://travis-ci.org/CargoSense/iona.svg?branch=master)](https://travis-ci.org/CargoSense/iona)

Document generation (pdf, dvi) from Elixir, using LaTeX.

## Highlighted Features

Nothing really yet, as this is just aspirational documentation, but it
will have:

* Generate professional-quality typeset `.pdf` (and `.dvi`) documents using
  [LaTeX](http://www.latex-project.org/)
* Built-in support for EEx templating with LaTeX-escaping helpers
* Advanced usage: preprocessor support (for bibliographies, etc)

## Prerequisites

While features are on the roadmap to ease authorship of `.tex` documents,
at the current time knowledge of LaTeX is assumed (or at least a basic
willingness to wade into that very deep topic).

We recommend you start your knowledge quest at the
[LaTeX homepage](http://www.latex-project.org/).

## Installation

Add as a dependency to your `mix.exs`:

```elixir
def deps do
  [
    iona: "~> 0.1"
  ]
end
```

Install it with `mix deps.get` and don't forget to add it to your applications list:

```elixir
def application do
  [applications: [:iona]]
end
```

## Examples

### From TeX source

Generate a PDF from an existing `.tex` source:

```elixir
File.read!("simple.tex")
|> Iona.pdf(output: "/path/to/simple.pdf")
```

Use a prepocessing pipeline (for bibliographies, etc):

```elixir
File.read!("academic.tex")
|> Iona.pdf(output: "/path/to/academic.pdf", preprocess: ~w(latex bibtex latex))
```

For more examples, see the documentation for
[Iona.pdf/1](http://hexdocs.pm/iona/Iona.html#pdf/1),
[Iona.pdf!/1](http://hexdocs.pm/iona/Iona.html#pdf!/1),
[Iona.dvi/1](http://hexdocs.pm/iona/Iona.html#dvi/1), and
[Iona.dvi!/1](http://hexdocs.pm/iona/Iona.html#dvi!/1).

## From an EEx TeX template

```elixir
%{title: "My Document"}
|> Iona.template(path: "/path/to/template.tex.eex")
|> Iona.pdf(output: "/path/to/my_document.pdf")
```

For more examples, see the documentation for
[Iona.template/1](http://hexdocs.pm/iona/Iona.html#template/1),

## Configuration

The default, out-of-the-box settings for Iona are equivalent to the
following Mix config:

```elixir
config :iona,
  default_preprocess: [],
  processors: [pdf: "pdflatex", dvi: "latex"]
  ```

Note you can also pass a `:preprocess` option to define a preprocessing pipeline
on a case-by-case basis.

```elixir
tex_string |> Iona.pdf(preprocess: ~w(latex bibtex latex))
```

## License

See [LICENSE](./LICENSE).

### LaTeX

LaTeX is free software, and is not distributed with this (unaffiliated) project.
Please see the [LaTeX homepage](https://latex-project.org) for more information.
