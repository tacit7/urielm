defmodule Urielm.EmbedParser do
  @moduledoc """
  Parses content for embeddable URLs (YouTube, images, etc.) and generates embed HTML.
  """

  @youtube_regex ~r/(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})/
  @image_regex ~r/https?:\/\/[^\s]+\.(?:jpg|jpeg|png|gif|webp)(?:\?[^\s]*)?/i
  @tweet_regex ~r/https?:\/\/(?:twitter\.com|x\.com)\/\w+\/status\/(\d+)/

  @doc """
  Process content and replace URLs with embeds.
  Returns HTML-safe string with embeds.
  """
  def process_embeds(content) when is_binary(content) do
    content
    |> embed_youtube()
    |> embed_images()
    |> embed_tweets()
  end

  def process_embeds(nil), do: ""

  @doc """
  Extract YouTube video ID from URL.
  """
  def extract_youtube_id(url) do
    case Regex.run(@youtube_regex, url) do
      [_full, video_id] -> video_id
      _ -> nil
    end
  end

  defp embed_youtube(content) do
    Regex.replace(@youtube_regex, content, fn full_match, video_id ->
      """
      <div class="youtube-embed my-4">
        <div class="relative w-full" style="padding-bottom: 56.25%;">
          <iframe
            class="absolute top-0 left-0 w-full h-full rounded-lg"
            src="https://www.youtube.com/embed/#{video_id}"
            frameborder="0"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
            allowfullscreen
          ></iframe>
        </div>
        <p class="text-xs text-base-content/50 mt-1">
          <a href="#{full_match}" target="_blank" rel="noopener" class="link">
            Watch on YouTube
          </a>
        </p>
      </div>
      """
    end)
  end

  defp embed_images(content) do
    Regex.replace(@image_regex, content, fn url ->
      """
      <div class="image-embed my-4">
        <img
          src="#{url}"
          alt="Embedded image"
          class="max-w-full h-auto rounded-lg cursor-pointer hover:opacity-90 transition-opacity"
          onclick="window.open('#{url}', '_blank')"
          loading="lazy"
        />
      </div>
      """
    end)
  end

  defp embed_tweets(content) do
    # For now, just make tweets clickable links with preview text
    # Full Twitter embed would require oEmbed API or Twitter widget.js
    Regex.replace(@tweet_regex, content, fn full_match, tweet_id ->
      """
      <div class="tweet-embed my-4 p-4 border border-base-300 rounded-lg bg-base-200/50">
        <p class="text-sm mb-2">
          <span class="font-semibold">Tweet ##{tweet_id}</span>
        </p>
        <a href="#{full_match}" target="_blank" rel="noopener" class="link link-primary text-sm">
          View on X/Twitter →
        </a>
      </div>
      """
    end)
  end

  @doc """
  Check if content contains any embeddable URLs.
  """
  def has_embeds?(content) when is_binary(content) do
    Regex.match?(@youtube_regex, content) ||
      Regex.match?(@image_regex, content) ||
      Regex.match?(@tweet_regex, content)
  end

  def has_embeds?(_), do: false
end
