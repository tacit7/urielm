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

      "https://tldr.tech/api/rss/ai" ->
        {:ok,
         %{
           status: 200,
           body: """
           <rss>
             <channel>
               <item>
                 <title><![CDATA[TLDR AI update]]></title>
                 <description><![CDATA[TLDR covered a useful AI update. It affects developers.]]></description>
                 <link>https://tldr.tech/ai/2026-08-26</link>
                 <pubDate>Wed, 26 Aug 2026 18:00:00 +0000</pubDate>
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

    assert {:ok, [openai, microsoft, tldr_ai, anthropic]} =
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

    assert tldr_ai.title == "TLDR AI update"
    assert tldr_ai.source == "TLDR AI"
    assert tldr_ai.url == "https://tldr.tech/ai/2026-08-26"
    assert tldr_ai.published_on == ~D[2026-08-26]
    assert tldr_ai.summary == "TLDR covered a useful AI update. It affects developers."

    assert anthropic.title == "Anthropic AI update"
    assert anthropic.source == "Anthropic"
    assert anthropic.url == "https://www.anthropic.com/news/claude-example"
    assert anthropic.published_on == ~D[2026-08-27]
    assert anthropic.created_at == ~U[2026-08-27 12:00:00Z]
  end

  test "collect_articles writes manifest and full article markdown files" do
    output_dir =
      Path.join([
        System.tmp_dir!(),
        "urielm-news-bot-test-#{System.unique_integer([:positive])}"
      ])

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
                 <description><![CDATA[OpenAI announced a useful AI update.]]></description>
                 <link>https://openai.com/index/in-range</link>
                 <pubDate>Tue, 25 Aug 2026 12:30:00 GMT</pubDate>
               </item>
             </channel>
           </rss>
           """
         }}

      "https://openai.com/index/in-range" ->
        {:ok,
         %{
           status: 200,
           body: """
           <html>
             <body>
               <nav>Navigation should be ignored when article exists</nav>
               <article>
                 <h1>Useful AI update</h1>
                 <p>The full article explains the release in useful detail.</p>
                 <p>It includes practical notes for builders.</p>
               </article>
             </body>
           </html>
           """
         }}
    end

    try do
      assert {:ok, result} =
               NewsBot.collect_articles(
                 from: ~D[2026-08-25],
                 to: ~D[2026-08-25],
                 limit: 10,
                 output_dir: output_dir,
                 sources: [
                   %{
                     name: "OpenAI",
                     type: :rss,
                     url: "https://openai.com/news/rss.xml"
                   }
                 ],
                 fetcher: fetcher
               )

      assert result.output_dir == Path.expand(output_dir)
      assert [article] = result.articles
      assert article.title == "Useful AI update"
      assert article.fetch_status == "fetched"
      assert File.exists?(result.manifest_path)
      assert File.exists?(result.readme_path)
      assert File.exists?(article.path)

      manifest = result.manifest_path |> File.read!() |> Jason.decode!()
      assert manifest["count"] == 1
      assert [manifest_article] = manifest["articles"]
      assert manifest_article["source"] == "https://openai.com/index/in-range"
      assert manifest_article["path"] == article.path

      markdown = File.read!(article.path)
      assert markdown =~ "# Useful AI update"
      assert markdown =~ "Source: https://openai.com/index/in-range"
      assert markdown =~ "The full article explains the release in useful detail."
      assert markdown =~ "It includes practical notes for builders."
    after
      File.rm_rf(output_dir)
    end
  end
end
