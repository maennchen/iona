Iona
====
[![Build Status](https://travis-ci.org/CargoSense/iona.svg?branch=master)](https://travis-ci.org/CargoSense/iona)

Document generation from Elixir, using LaTeX.

## Highlighted Features

* Generate professional-quality typeset `.pdf` (and `.dvi`) documents using
  [LaTeX](http://www.latex-project.org/), and support defining your own
  TeX processors for different formats.
* Built-in support for EEx templating with automatic escaping and a custom helpers
* Preprocessing support (multiple runs for bibliographies, etc)

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
    iona: "~> 0.3"
  ]
end
```

Install it with `mix deps.get` and don't forget to add it to your applications list:

```elixir
def application do
  [applications: [:iona]]
end
```

## LaTeX

Of course you need a TeX system installed, including `latex`, `pdflatex`,
or any other variants you'd like to use to process your `.tex` source into final
documents. (The default configuration assumes `pdflatex` is installed for PDF
generation and `latex` is installed for DVI generation. See "Configuration," below.)

You can download and install a TeX system at the
[LaTeX Project website](https://latex-project.org/ftp.html) -- or using the
the package management system of your choice.

## Examples

### From TeX source

Generate a PDF from an existing `.tex` source:

```elixir
Iona.source(path: "simple.tex")
|> Iona.write!("/path/to/document.pdf")
```

You can also use a binary string:

```elixir
Iona.source("\documentclass[12pt]{article} ...")
|> Iona.write!("/path/to/simple.pdf")
```

More complex preprocessing needs for citations and bibliographies?
Define the prepocessing pipeline:

```elixir
Iona.source(path: "academic.tex")
|> Iona.write!("/path/to/academic.pdf",
               preprocess: ~w(latex bibtex latex))
```

Want to get the raw document content as a binary? Use `to`:

```elixir
Iona.source(path: "fancy.tex")
|> Iona.to(:pdf)
|> MyModule.do_something_with_pdf_string
```

### Complex preprocessors

You can provide functions in the preprocessing pipeline too. The function will
be invoked, given the temporary directory processing is occuring and the
basename of the original file (eg, `"source.tex"`):

```elixir
Iona.source(path: "source.tex")
|> Iona.write!("/path/to/source.pdf",
               preprocess: [fn (directory, filename) -> :ok end])
```

Function preprocessors should return:

* `:ok` if processing should continue
* `{:shell, command}` to indicate a command should be run as a preprocessor (see example below)
* `{:error, reason}` if processing should halt

If given `{:shell, command}`, Iona will execute that command as a preprocessor.
This is especially useful for interpolation, eg:

```elixir
knitr = fn (_, filename) ->
  {:shell, "R -e 'library(knitr);knitr(\"#{filename}\");'" }
end

Iona.source(path: "graphs.Rnw")
|> Iona.write!("/path/to/graphs.pdf",
               preprocess: [knitr])
```

Important: As always, only interpolate trusted input into shell commands.

## From an EEx TeX template

```elixir
%{title: "My Document"}
|> Iona.template(path: "/path/to/template.tex.eex")
|> Iona.write("/path/to/my_document.pdf")
```

Values are inserted into EEx with, eg, `<%= @title %>` after being automatically
escaped by `Iona.Template.Helper.escape/1`.

If you're confident values are safe for raw insertion into your LaTeX documents
(or you'd like to support insertion of LaTeX commands), use `raw/1`, made
available by default as part of `Iona.Template.Helper`:

For instance, if you wanted to style `@title` as boldface, you could pass it
as `"{\bf My Document}"` and insert it as a raw string:

```
<%= raw @title %>
```

### With Custom Helpers

You can import additional helper modules for use in your templates by two methods.

The first (and preferred) method is by overriding the `:helpers` application
configuration setting (see "Configuration," below).

You can also pass a `:helpers` option to `Iona.template/1` with a list of
additional helpers:

```elixir
%{title: "My Document"}
|> Iona.template(path: "/path/to/template.tex.eex",
                 helpers: [My.Custom.HelperModule])
|> Iona.write("/path/to/my_document.pdf")
```

Note in this case the setting is additive; the list is concatenated with the
`:helpers` defined in the application configuration.

## Configuration

The default, out-of-the-box settings for Iona are equivalent to the
following Mix config:

```elixir
config :iona,
  helpers: [Iona.Template.Helper],
  preprocess: [],
  processors: [pdf: "pdflatex", dvi: "latex"]
  ```

Note you can also pass a `:preprocess` and `:processor` options to define a preprocessing pipeline
on a case-by-case basis. See the examples above or the documentation for `Iona.to/3` and `Iona.write/3`.

## License

See [LICENSE](./LICENSE).

### LaTeX

LaTeX is free software, and is not distributed with this (unaffiliated) project.
Please see the [LaTeX homepage](https://latex-project.org) for more information.
