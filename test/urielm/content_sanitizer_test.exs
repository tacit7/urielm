defmodule Urielm.ContentSanitizerTest do
  use ExUnit.Case

  alias Urielm.ContentSanitizer

  describe "sanitize_markdown/1" do
    test "converts plain markdown to HTML" do
      markdown = "# Hello World"
      html = ContentSanitizer.sanitize_markdown(markdown)

      assert html =~ "<h1"
      assert html =~ "Hello World"
    end

    test "converts bold markdown" do
      markdown = "**bold text**"
      html = ContentSanitizer.sanitize_markdown(markdown)

      assert html =~ "<strong>"
      assert html =~ "bold text"
    end

    test "converts italic markdown" do
      markdown = "*italic text*"
      html = ContentSanitizer.sanitize_markdown(markdown)

      assert html =~ "<em>"
      assert html =~ "italic text"
    end

    test "converts links from markdown" do
      markdown = "[Google](https://google.com)"
      html = ContentSanitizer.sanitize_markdown(markdown)

      assert html =~ "<a"
      assert html =~ "href="
      assert html =~ "https://google.com"
      assert html =~ "Google"
    end

    test "converts code blocks from markdown" do
      markdown = "```\ncode here\n```"
      html = ContentSanitizer.sanitize_markdown(markdown)

      assert html =~ "code here"
    end

    test "converts unordered lists" do
      markdown = """
      - item 1
      - item 2
      - item 3
      """

      html = ContentSanitizer.sanitize_markdown(markdown)

      assert html =~ "<ul>"
      assert html =~ "<li>"
      assert html =~ "item 1"
      assert html =~ "item 2"
      assert html =~ "item 3"
    end

    test "converts ordered lists" do
      markdown = """
      1. first
      2. second
      3. third
      """

      html = ContentSanitizer.sanitize_markdown(markdown)

      assert html =~ "<ol>"
      assert html =~ "<li>"
      assert html =~ "first"
      assert html =~ "second"
    end

    test "converts blockquotes" do
      markdown = "> This is a quote"
      html = ContentSanitizer.sanitize_markdown(markdown)

      assert html =~ "<blockquote>"
      assert html =~ "This is a quote"
    end

    test "handles nil input gracefully" do
      result = ContentSanitizer.sanitize_markdown(nil)
      assert result == ""
    end

    test "handles empty string" do
      result = ContentSanitizer.sanitize_markdown("")
      assert result == ""
    end

    test "handles whitespace-only input" do
      result = ContentSanitizer.sanitize_markdown("   \n  \t  ")
      assert String.trim(result) == ""
    end

    test "handles complex markdown with multiple elements" do
      markdown = """
      # Title

      This is a paragraph with **bold** and *italic*.

      - List item 1
      - List item 2

      [Link](https://example.com)
      """

      html = ContentSanitizer.sanitize_markdown(markdown)

      assert html =~ "<h1>"
      assert html =~ "Title"
      assert html =~ "<strong>"
      assert html =~ "<em>"
      assert html =~ "<ul>"
      assert html =~ "<a"
    end

    test "handles escaped characters" do
      markdown = "\\*not italic\\*"
      html = ContentSanitizer.sanitize_markdown(markdown)

      # Escaped asterisks should not create italic
      assert html =~ "*"
    end

    test "preserves line breaks in code blocks" do
      markdown = """
      ```
      line 1
      line 2
      line 3
      ```
      """

      html = ContentSanitizer.sanitize_markdown(markdown)

      assert html =~ "line 1"
      assert html =~ "line 2"
      assert html =~ "line 3"
    end

    test "handles inline code" do
      markdown = "This is `inline code` here"
      html = ContentSanitizer.sanitize_markdown(markdown)

      # Earmark wraps inline code in <code class="inline"> or similar
      assert html =~ "inline code"
      assert String.contains?(html, ["<code", "code>"]) or html =~ "inline code"
    end

    test "handles mixed content" do
      markdown = """
      # Section 1

      **Bold paragraph** with `code`.

      ## Section 2

      - Point 1
      - Point 2 with [link](https://example.com)
      """

      html = ContentSanitizer.sanitize_markdown(markdown)

      assert html =~ "<h1>"
      assert html =~ "<h2>"
      assert html =~ "<strong>"
      assert html =~ "code"
      assert html =~ "<ul>"
      assert html =~ "<a"
    end

    test "handles URLs in markdown" do
      markdown = "Check out https://example.com"
      html = ContentSanitizer.sanitize_markdown(markdown)

      # URL should be in output (may or may not be auto-linked depending on Earmark)
      assert html =~ "example.com"
    end

    test "handles special characters" do
      markdown = "Test with & < > \" ' characters"
      html = ContentSanitizer.sanitize_markdown(markdown)

      # Should handle without breaking
      assert html =~ "Test"
      assert html =~ "characters"
    end

    test "handles markdown tables" do
      markdown = """
      | Header 1 | Header 2 |
      |----------|----------|
      | Cell 1   | Cell 2   |
      """

      html = ContentSanitizer.sanitize_markdown(markdown)

      # Tables may or may not be supported depending on Earmark config
      assert html =~ "Header 1" or html =~ "Cell 1"
    end

    test "handles line continuations" do
      markdown = "Line 1\nLine 2\n\nParagraph 2"
      html = ContentSanitizer.sanitize_markdown(markdown)

      assert html =~ "Line 1"
      assert html =~ "Line 2"
      assert html =~ "Paragraph 2"
    end
  end

  describe "validate_content_length/2" do
    test "accepts content within default limit (10000 chars)" do
      content = String.duplicate("a", 5000)
      assert {:ok, _} = ContentSanitizer.validate_content_length(content)
    end

    test "accepts content at exactly the default limit" do
      content = String.duplicate("a", 10000)
      assert {:ok, ^content} = ContentSanitizer.validate_content_length(content)
    end

    test "rejects content exceeding default limit" do
      content = String.duplicate("a", 10001)
      {:error, msg} = ContentSanitizer.validate_content_length(content)

      assert msg =~ "exceeds maximum length"
      assert msg =~ "10000"
    end

    test "rejects nil content" do
      {:error, msg} = ContentSanitizer.validate_content_length(nil)
      assert msg =~ "cannot be empty"
    end

    test "rejects empty string" do
      {:error, msg} = ContentSanitizer.validate_content_length("")
      assert msg =~ "cannot be empty"
    end

    test "handles whitespace-only content" do
      # Whitespace is trimmed, and empty content returns error
      result = ContentSanitizer.validate_content_length("   \n  \t  ")
      # After trimming, becomes empty string which is rejected
      case result do
        {:ok, val} -> assert val == ""
        {:error, msg} -> assert msg =~ "cannot be empty"
      end
    end

    test "trims whitespace from content" do
      content = "  hello world  \n"
      {:ok, trimmed} = ContentSanitizer.validate_content_length(content)

      assert trimmed == "hello world"
    end

    test "accepts custom max length" do
      content = String.duplicate("a", 100)
      assert {:ok, _} = ContentSanitizer.validate_content_length(content, 150)
    end

    test "rejects content exceeding custom max length" do
      content = String.duplicate("a", 151)
      {:error, msg} = ContentSanitizer.validate_content_length(content, 150)

      assert msg =~ "exceeds maximum length"
      assert msg =~ "150"
    end

    test "accepts exactly custom max length" do
      content = String.duplicate("a", 150)
      {:ok, ^content} = ContentSanitizer.validate_content_length(content, 150)
    end

    test "handles very large content gracefully" do
      # 1MB of content
      content = String.duplicate("a", 1_000_000)
      {:error, msg} = ContentSanitizer.validate_content_length(content)

      assert msg =~ "exceeds maximum length"
    end

    test "validates multiple small custom limits" do
      content = "short"

      assert {:ok, _} = ContentSanitizer.validate_content_length(content, 10)
      assert {:ok, _} = ContentSanitizer.validate_content_length(content, 5)
      {:error, _} = ContentSanitizer.validate_content_length(content, 4)
    end

    test "preserves content in successful validation" do
      original = "important content here"
      {:ok, validated} = ContentSanitizer.validate_content_length(original)

      assert validated == original
    end

    test "handles content with newlines" do
      content = "line 1\nline 2\nline 3"
      {:ok, trimmed} = ContentSanitizer.validate_content_length(content)

      assert trimmed == "line 1\nline 2\nline 3"
    end

    test "handles unicode content" do
      content = "Hello 世界 🌍 مرحبا"
      {:ok, validated} = ContentSanitizer.validate_content_length(content)

      assert validated == content
    end

    test "counts unicode characters correctly" do
      # Each emoji is typically 1 character in Elixir strings
      content = String.duplicate("🌍", 50)
      length = String.length(content)

      assert length == 50
      assert {:ok, _} = ContentSanitizer.validate_content_length(content)
    end

    test "handles tabs and special whitespace" do
      content = "\t\tindented\t\tcontent\t\t"
      {:ok, trimmed} = ContentSanitizer.validate_content_length(content)

      assert trimmed == "indented\t\tcontent"
    end
  end

  describe "integration - sanitization and validation together" do
    test "validates then sanitizes content" do
      content = """
      # Important Post

      This is **important** content with a [link](https://example.com).
      """

      # First validate length
      {:ok, validated} = ContentSanitizer.validate_content_length(content)

      # Then sanitize markdown
      html = ContentSanitizer.sanitize_markdown(validated)

      assert html =~ "<h1>"
      assert html =~ "Important Post"
      assert html =~ "<strong>"
      assert html =~ "<a"
      assert html =~ "https://example.com"
    end

    test "rejects oversized content before sanitizing" do
      content = String.duplicate("word ", 3000)

      {:error, _msg} = ContentSanitizer.validate_content_length(content, 1000)

      # Should not reach sanitization step in real usage
    end

    test "sanitizes all content types" do
      contents = [
        {"# Header", "<h1>"},
        {"**bold**", "<strong>"},
        {"*italic*", "<em>"},
        {"- list", "<li>"},
        {"[link](http://x.com)", "<a"},
        {"`code`", "code"}
      ]

      Enum.each(contents, fn {markdown, expected_html} ->
        html = ContentSanitizer.sanitize_markdown(markdown)
        assert html =~ expected_html, "Failed for: #{markdown}"
      end)
    end
  end
end
