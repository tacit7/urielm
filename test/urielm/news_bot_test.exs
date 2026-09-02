defmodule Urielm.NewsBotTest do
  use Urielm.DataCase

  import Urielm.Fixtures

  alias Urielm.NewsBot
  alias Urielm.NewsBot.DateParser

  test "date parser handles source date labels" do
    assert DateParser.parse("August 25, 2026") == {:ok, ~D[2026-08-25]}
    assert DateParser.parse("Aug 25, 2026") == {:ok, ~D[2026-08-25]}

    assert DateParser.parse_rfc822("Tue, 25 Aug 2026 12:30:00 GMT") ==
             {:ok, ~U[2026-08-25 12:30:00Z]}

    assert DateParser.parse_rfc822("Tue, 25 Aug 2026 12:30:00 +0000") ==
             {:ok, ~U[2026-08-25 12:30:00Z]}

    assert DateParser.parse("bad date") == :error
  end

  test "discover returns dated multi-source candidates and skips already posted source URLs" do
    board = board_fixture(%{slug: "ai-news"})

    thread_fixture(%{
      board_id: board.id,
      body: "Existing source: https://openai.com/index/already-posted/"
    })

    fetcher = fn
      "https://openai.com/news/rss.xml" ->
        {:ok,
         %{
           status: 200,
           body: """
           <rss>
             <channel>
               <item>
                 <title><![CDATA[Useful AI update]]></title>
                 <description><![CDATA[OpenAI announced a useful AI update. It changes developer workflows.]]></description>
                 <link>https://openai.com/index/in-range</link>
                 <pubDate>Tue, 25 Aug 2026 12:30:00 GMT</pubDate>
               </item>
               <item>
                 <title><![CDATA[Old AI update]]></title>
                 <description><![CDATA[OpenAI announced an older AI update.]]></description>
                 <link>https://openai.com/index/out-of-range</link>
                 <pubDate>Mon, 10 Aug 2026 12:00:00 GMT</pubDate>
               </item>
               <item>
                 <title><![CDATA[Duplicate AI update]]></title>
                 <description><![CDATA[OpenAI announced a duplicate AI update.]]></description>
                 <link>https://openai.com/index/already-posted</link>
                 <pubDate>Tue, 25 Aug 2026 13:00:00 GMT</pubDate>
               </item>
             </channel>
           </rss>
           """
         }}

      "https://news.microsoft.com/source/topics/ai/feed/" ->
        {:ok,
         %{
           status: 200,
           body: """
           <rss>
             <channel>
               <item>
                 <title><![CDATA[Microsoft AI update]]></title>
                 <description><![CDATA[<p>Microsoft shipped an AI update. It is useful.</p>]]></description>
                 <link>https://news.microsoft.com/source/features/ai/microsoft-ai-update/</link>
                 <pubDate>Wed, 26 Aug 2026 15:07:06 +0000</pubDate>
               </item>
             </channel>
           </rss>
           """
         }}

      "https://www.anthropic.com/news" ->
        {:ok,
         %{
           status: 200,
           body: """
           <html>
             <a href="/news/claude-example">Claude example</a>
           </html>
           """
         }}

      "https://www.anthropic.com/news/claude-example" ->
        {:ok,
         %{
           status: 200,
           body: """
           <html>
             <head>
               <meta property="og:title" content="Anthropic AI update"/>
               <meta property="og:description" content="Anthropic published a useful AI update."/>
             </head>
             <body>Aug 27, 2026</body>
           </html>
           """
         }}
    end

    assert {:ok, [openai, microsoft, anthropic]} =
             NewsBot.discover(
               from: ~D[2026-08-22],
               to: ~D[2026-08-28],
               limit: 7,
               fetcher: fetcher
             )

    assert openai.title == "Useful AI update"
    assert openai.source == "OpenAI"
    assert openai.url == "https://openai.com/index/in-range"
    assert openai.published_on == ~D[2026-08-25]
    assert openai.created_at == ~U[2026-08-25 12:30:00Z]
    assert openai.body =~ "Publisher: OpenAI"
    assert openai.body =~ "Source: https://openai.com/index/in-range"

    assert microsoft.title == "Microsoft AI update"
    assert microsoft.source == "Microsoft"
    assert microsoft.url == "https://news.microsoft.com/source/features/ai/microsoft-ai-update"
    assert microsoft.published_on == ~D[2026-08-26]
    assert microsoft.summary == "Microsoft shipped an AI update. It is useful."

    assert anthropic.title == "Anthropic AI update"
    assert anthropic.source == "Anthropic"
    assert anthropic.url == "https://www.anthropic.com/news/claude-example"
    assert anthropic.published_on == ~D[2026-08-27]
    assert anthropic.created_at == ~U[2026-08-27 12:00:00Z]
  end
end
