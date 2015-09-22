defmodule Pandoc.Wrapper do
  @readers ["markdown", "json", "rst", "textile", "html", "latex"]
  @writers [ "json", "html", "html5", "s5", "slidy", "dzslides", "docbook", "man",
            "opendocument", "latex", "beamer", "context", "texinfo", "markdown",
            "plain", "rst", "mediawiki", "textile", "rtf", "org", "asciidoc" ]

  Enum.each @readers, fn (reader) ->
    Enum.each @writers, fn (writer) ->
      #function names are atoms. Hence converting String to Atom here:
      def unquote(:"#{reader}_to_#{writer}")(string) do
        convert_string(string, unquote(reader), unquote(writer))
      end
    end
  end

  def convert_string(string, from \\ "markdown", to \\ "html", _options \\ []) do
    if !File.dir?(".temp"), do: File.mkdir ".temp"
    name = ".temp/" <> random_name
    File.write name, string
    {output,_} = System.cmd "pandoc", [name , "--from=#{from}" , "--to=#{to}"]
    File.rm name
    {:ok, output}
  end

  defp random_name do
    random_string <> "-" <> timestamp <> ".temp"
  end

  defp random_string do
    0x100000000000000 |> :random.uniform |> Integer.to_string(36) |> String.downcase
  end

  defp timestamp do
    {megasec, sec, _microsec} = :os.timestamp
    megasec*1_000_000 + sec |> Integer.to_string()
  end
end
