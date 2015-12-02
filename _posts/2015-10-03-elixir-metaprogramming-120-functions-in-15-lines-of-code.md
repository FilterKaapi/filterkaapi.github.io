---
layout: post
title: "Elixir Metaprogramming: 120 functions in 15 lines of code"
comments: true
permalink: "elixir-metaprogramming-120-functions-in-15-lines-of-code"
---

![Meta](http://imgs.xkcd.com/comics/hofstadter.png)

## What is Elixir?

![elixir logo](http://elixir-lang.org/images/logo/logo.png)

Elixir is a dynamic, functional language designed for building scalable and maintainable applications.It has a Ruby-like syntax. Elixir also leverages the Erlang VM, known for running low-latency, distributed and fault-tolerant systems, while also being successfully used in web development and the embedded software domain.

In other words:

```elixir
Elixir = Ruby Syntax + Erlang VM
```

Ruby like syntax enables terrific productivity, while Erlang results in amazing performance.

## What is Metaprogramming?

Metaprogramming is the process of writing a program that writes programs. Elixir is said to have powerful metaprogramming. I wanted to test out how powerful it was. So, I decided to write a sample program.

## Sample Program: An elixir wrapper for Pandoc

Pandoc is an haskell based library that allows you to convert documents in the combination of formats. It's a swiss army knife of document conversion. We want to create an Elixir program that will allow us to convert a file from one format to another using a syntax like:

```elixir
markdown_to_html "sample.md"
```

## Step 1: Install Elixir

Incase you don't already have elixir installed, you can install Elixir from instructions given here. The installation process is pretty straight forward.

## Step 2: Install Pandoc

Install Pandoc for your operating system with instructions given [here](http://pandoc.org). When you successfully install Pandoc, you will have the `pandoc` command available to you in the command line. Check if Pandoc is installed with the `pandoc --version` command in the your terminal.

Pandoc expects a file as an input. Let's make a simple markdown file `sample.md` with the following content for testing purposes:

**sample.md**

```

# title

## Chapter

### list

- one
- two
- three

```

In order to convert a `sample.md` from one format to another (say HTML) we run the following command in the terminal:

```bash
pandoc sample.md --from=markdown --to=html
```

This will give you the following output:

```html
<h1 id="title">title</h1>
<h2 id="chapter">Chapter</h1>
<h3 id="list">list</h2>
<ul>
  <li>one</li>
  <li>two</li>
  <li>three</li>
</ul>
```

## Step 3: Create `pandoc_wrapper.exs`

The `System.cmd` function in elixir allows you to run bash commands from your elixir program or console. Thus in order to run `pandoc sample.md --from=markdown --to=html` from our elixir program we call the function as

```elixir
System.cmd "pandoc", ["sample.md", "--from=markdown", "--to=html"]
```

This will give the following output:

```elixir
{"<h1 id=\"title\">title</h1>\n<h2 id=\"chapter\">Chapter</h2>\n<h3 id=\"list\">list</h3>\n<ul>\n<li>one</li>\n<li>two</li>\n<li>three</li>\n</ul>\n", 0}
```

Which is a tuple of the form `{output,0}`. We can thus pattern match the output as follows:

```elixir
{output, _} = System.cmd "pandoc", ["sample.md", "--from=markdown", "--to=html"]
```

`_` implies that we do not care what that operator is.

Let's now get put all this together in an elixir program. In your code folder create a file named `pandoc_wrapper.exs`. The `exs` extension stands for `elixir script`.

```elixir
defmodule Pandoc.Wrapper do
  def convert(file, from \\ "markdown", to \\ "html" ) do
    {output,_} = System.cmd "pandoc", [file , "--from=#{from}" , "--to=#{to}"]
  end
end
```

We are passing 3 arguments to the convert function:
- `file` is the file what we want to convert
- `from` is the current format of the file. `markdown` is the default format in case no argument is passed.
- `to` is the format to which you want to convert. `html` is the default format in case no argument is passed.
- `\\` stands for the default value of the argument.

## Step 4: Metaprogram to create conversion functions

Pandoc can accept documents in certain formats and export them to certain formats. In order to define our functions of the form `markdown_to_html`, we need to define functions as follows:

```elixir
def markdown_to_html(file) do
  {output, _} = convert file, "markdown", "html"
  {:ok, output}
end
```  

There are currently 6 reader formats and 21 writer formats. This implies that have a total of 126 possible combination of conversions. To write custom functions for each of them is extremely time consuming. Let's use metaprogramming to reduce our workload.

Firstly, let's store the input and output formats in two lists name `@readers` and `@writers` respectively.

**pandoc_wrapper.exs**

```elixir
defmodule Pandoc.Wrapper do
  @readers ["markdown", "json", "rst", "textile", "html", "latex"]
  @writers [ "json", "html", "html5", "s5", "slidy", "dzslides", "docbook", "man",
            "opendocument", "latex", "beamer", "context", "texinfo", "markdown",
            "plain", "rst", "mediawiki", "textile", "rtf", "org", "asciidoc" ]

  def convert(file, from \\ "markdown", to \\ "html ) do
    {output,_} = System.cmd "pandoc", [file , "--from=#{from}" , "--to=#{to}"]
  end
end
```

Next, we will loop through the `@readers` and `@writers` list to create our custom functions with metaprogramming as follows:

```elixir
Enum.each @readers, fn (reader) ->
  Enum.each @writers, fn (writer) ->
    def unquote(:"#{reader}_to_#{writer}")(string) do
      convert(string, unquote(reader), unquote(writer))
    end
  end
end
```

- `Enum.each` loops through each element of the list (`@readers`, `@writers`)
- `unquote` injects each `reader` and `writer` variable in `:"#{reader}_to_#{writer}"`.
- `:` converts the string to an atom. Functions in elixir must be atoms.
- Within the function definition, we call the `convert` function that we defined before, passing the `reader` and `writer` variables into the function.

## Step 5: Putting it all together

**pandoc_wrapper.exs**

```elixir
defmodule Pandoc.Wrapper do
  @readers ["markdown", "json", "rst", "textile", "html", "latex"]
  @writers [ "json", "html", "html5", "s5", "slidy", "dzslides", "docbook", "man", "opendocument", "latex", "beamer",
  "context", "texinfo", "markdown", "plain", "rst", "mediawiki", "textile", "rtf", "org", "asciidoc" ]

  Enum.each @readers, fn (reader) ->
    Enum.each @writers, fn (writer) ->
      def unquote(:"#{reader}_to_#{writer}")(string) do
        convert(string, unquote(reader), unquote(writer))
      end
    end
  end

  def convert(file, from \\ "markdown", to \\ "html ) do
    {output,_} = System.cmd "pandoc", [file , "--from=#{from}" , "--to=#{to}"]
  end
end
```

# Testing It

Let's open an interactive elixir shell with `iex` in terminal.

```elixir
iex> import Pandoc.Wrapper
iex> markdown_to_html "sample.md"
{:ok, "<h1 id=\"title\">title</h1>\n<h2 id=\"chapter\">Chapter</h2>\n<h3 id=\"list\">list</h3>\n<ul>\n<li>one</li>\n<li>two</li>\n<li>three</li>\n</ul>\n"}
```

It works!

## Conclusion

There it is! In less than 15 lines of code we have generated over 120 functions. This is a very simple example of Elixir metaprogramming. We can perform much more powerful metaprogramming with Elixir Macros which I will cover later.

You can also convert this into an Elixir package, which is exactly what I have done. You can check out [Pandex](http://hex.pm/packages/pandex), the lightweight Elixir wrapper for Pandoc on [Github](https://github.com/filterkaapi/pandex).
___

<style>
  .gumroad-follow-form-embed {
    zoom: 1; }
    .gumroad-follow-form-embed:before, .gumroad-follow-form-embed:after {
      display: table;
      line-height: 0;
      content: ""; }
    .gumroad-follow-form-embed:after {
      clear: both; }
    .gumroad-follow-form-embed * {
      margin: 0;
      border: 0;
      padding: 0;
      outline: 0;
      box-sizing: border-box !important;
      float: left !important; }
    .gumroad-follow-form-embed input {
      border-radius: 4px;
      border-top-right-radius: 0;
      border-bottom-right-radius: 0;
      font-family: -apple-system, ".SFNSDisplay-Regular", "Helvetica Neue", Helvetica, Arial, sans-serif;
      font-size: 15px;
      line-height: 20px;
      background: #fff;
      border: 1px solid #ddd;
      border-right: 0;
      color: #aaa;
      padding: 10px;
      box-shadow: inset 0 1px 0 rgba(0, 0, 0, 0.02);
      background-position: top right;
      background-repeat: no-repeat;
      text-rendering: optimizeLegibility;
      font-smoothing: antialiased;
      -webkit-appearance: none;
      -moz-appearance: caret;
      width: 65% !important;
      height: 40px !important; }
    .gumroad-follow-form-embed button {
      border-radius: 4px;
      border-top-left-radius: 0;
      border-bottom-left-radius: 0;
      box-shadow: 0 1px 1px rgba(0, 0, 0, 0.12);
      -webkit-transition: all .05s ease-in-out;
      transition: all .05s ease-in-out;
      display: inline-block;
      padding: 11px 15px 12px;
      cursor: pointer;
      color: #fff;
      font-size: 15px;
      line-height: 100%;
      font-family: -apple-system, ".SFNSDisplay-Regular", "Helvetica Neue", Helvetica, Arial, sans-serif;
      background: #36a9ae;
      border: 1px solid #31989d;
      filter: "progid:DXImageTransform.Microsoft.gradient(startColorstr=#5ccfd4, endColorstr=#329ca1, GradientType=0)";
      background: -webkit-linear-gradient(top, #5ccfd4, #329ca1);
      background: linear-gradient(to bottom, #5ccfd4, #329ca1);
      height: 40px !important;
      width: 35% !important; }
</style>
<form action="https://gumroad.com/follow_from_embed_form" class="form gumroad-follow-form-embed" method="post">
<input name="seller_id" type="hidden" value="3638569113408">
<input name="email" placeholder="Your email address" type="email">
<button type="submit">Follow</button>
</form>
