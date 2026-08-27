defmodule UrielmWeb.MarkdownTest do
  use ExUnit.Case

  alias UrielmWeb.Markdown

  describe "to_html/1" do
    test "strips script tags from rendered output" do
      markdown = "Hello <script>alert('xss')</script> world"
      {:safe, html} = Markdown.to_html(markdown)
      refute html =~ "<script>"
      assert html =~ "Hello"
      assert html =~ "world"
    end

    test "strips multiline script tags" do
      markdown = "Safe\n<script>\nevil()\n</script>\nContent"
      {:safe, html} = Markdown.to_html(markdown)
      refute html =~ "<script>"
      refute html =~ "evil()"
    end

    test "strips script tags with attributes" do
      markdown = "Text <script src=\"evil.js\">x</script> more"
      {:safe, html} = Markdown.to_html(markdown)
      refute html =~ "<script"
    end

    test "drops img onerror payloads and javascript: hrefs (SEC-4)" do
      markdown = """
      Look at this: <img src="https://example.com/x.png" onerror="stealCookies">

      [click me](javascript:stealCookies)
      """

      {:safe, html} = Markdown.to_html(markdown)

      refute html =~ "onerror"
      refute html =~ "javascript:"
      refute html =~ "stealCookies"
    end

    test "drops raw inline svg and iframe" do
      markdown = """
      <svg onload="stealCookies"></svg>
      <iframe src="https://evil.example"></iframe>
      """

      {:safe, html} = Markdown.to_html(markdown)

      refute html =~ "onload"
      refute html =~ "<svg"
      refute html =~ "<iframe"
    end

    test "renders standard markdown" do
      markdown = "# Title\n\n**bold** and *italic*"
      {:safe, html} = Markdown.to_html(markdown)
      assert html =~ "<h1>"
      assert html =~ "<strong>"
      assert html =~ "<em>"
    end

    test "handles nil gracefully" do
      {:safe, html} = Markdown.to_html(nil)
      assert html == ""
    end

    test "handles empty string" do
      {:safe, html} = Markdown.to_html("")
      assert html == ""
    end

    test "returns Phoenix.HTML.safe tuple" do
      result = Markdown.to_html("hello")
      assert match?({:safe, _}, result)
    end
  end

  describe "to_html!/1" do
    test "strips script tags" do
      markdown = "<script>alert(1)</script>"
      {:safe, html} = Markdown.to_html!(markdown)
      refute html =~ "<script>"
    end

    test "preserves code block class attributes for syntax highlighting" do
      markdown = "```elixir\ndef foo, do: :ok\n```"
      {:safe, html} = Markdown.to_html!(markdown, code_class_prefix: "language-")
      assert html =~ "language-elixir"
    end

    test "returns Phoenix.HTML.safe tuple" do
      result = Markdown.to_html!("hello")
      assert match?({:safe, _}, result)
    end
  end
end
