/**
 * HTML attribute value escaping to prevent XSS
 * Escapes characters that could break out of attribute quotes
 */
export function escapeAttr(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("\"", "&quot;")
    .replaceAll("'", "&#39;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
}

/**
 * Process markdown HTML to add embeds for YouTube, images, and Twitter
 * All URLs are properly escaped before interpolation
 */
export function processEmbeds(htmlContent) {
  let processed = htmlContent

  // YouTube embeds
  processed = processed.replace(
    /https?:\/\/(?:www\.)?(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})/g,
    (match, videoId) => {
      const safeVideoId = escapeAttr(videoId)
      return `
        <div class="youtube-embed my-4 not-prose">
          <div class="relative w-full rounded-lg overflow-hidden" style="padding-bottom: 56.25%;">
            <iframe
              class="absolute top-0 left-0 w-full h-full"
              src="https://www.youtube.com/embed/${safeVideoId}"
              frameborder="0"
              allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
              allowfullscreen
            ></iframe>
          </div>
        </div>
      `
    }
  )

  // Image embeds (not already in markdown img tags)
  // Tightened regex to exclude quotes from URL matching
  processed = processed.replace(
    /(?<!<img[^>]*src=")https?:\/\/[^\s<"'`]+\.(?:jpg|jpeg|png|gif|webp)(?:\?[^\s<"'`]*)?/gi,
    (url) => {
      const safeUrl = escapeAttr(url)
      return `
        <div class="image-embed my-4 not-prose">
          <a href="${safeUrl}" target="_blank" rel="noopener noreferrer">
            <img
              src="${safeUrl}"
              alt="Embedded image"
              class="max-w-full h-auto rounded-lg cursor-pointer hover:opacity-90 transition-opacity border border-base-300"
              loading="lazy"
            />
          </a>
        </div>
      `
    }
  )

  // Twitter/X embeds (basic preview)
  processed = processed.replace(
    /https?:\/\/(?:twitter\.com|x\.com)\/\w+\/status\/(\d+)/g,
    (match, tweetId) => {
      const safeMatch = escapeAttr(match)
      return `
        <div class="tweet-embed my-4 p-4 border border-primary/30 rounded-lg bg-base-200/50 not-prose">
          <div class="flex items-center gap-2 mb-2">
            <svg class="w-5 h-5 text-primary" fill="currentColor" viewBox="0 0 24 24">
              <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/>
            </svg>
            <span class="font-semibold text-sm">Post on X</span>
          </div>
          <a href="${safeMatch}" target="_blank" rel="noopener" class="link link-primary text-sm">
            View post →
          </a>
        </div>
      `
    }
  )

  return processed
}
