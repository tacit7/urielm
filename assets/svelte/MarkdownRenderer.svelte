<script>
  import MarkdownIt from 'markdown-it'
  import hljs from 'highlight.js'

  export let content = ''

  const md = new MarkdownIt({
    highlight: (code, lang) => {
      if (lang && hljs.getLanguage(lang)) {
        try {
          return hljs.highlight(code, { language: lang }).html
        } catch (__) {}
      }

      return md.utils.escapeHtml(code)
    }
  })

  let html = ''

  $: if (content) {
    html = md.render(content)
    html = processEmbeds(html)
  }

  function processEmbeds(htmlContent) {
    let processed = htmlContent

    // YouTube embeds
    processed = processed.replace(
      /https?:\/\/(?:www\.)?(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})/g,
      (match, videoId) => `
        <div class="youtube-embed my-4 not-prose">
          <div class="relative w-full rounded-lg overflow-hidden" style="padding-bottom: 56.25%;">
            <iframe
              class="absolute top-0 left-0 w-full h-full"
              src="https://www.youtube.com/embed/${videoId}"
              frameborder="0"
              allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
              allowfullscreen
            ></iframe>
          </div>
        </div>
      `
    )

    // Image embeds (not already in markdown img tags)
    processed = processed.replace(
      /(?<!<img[^>]*src=")https?:\/\/[^\s<]+\.(?:jpg|jpeg|png|gif|webp)(?:\?[^\s<]*)?/gi,
      (url) => `
        <div class="image-embed my-4 not-prose">
          <img
            src="${url}"
            alt="Embedded image"
            class="max-w-full h-auto rounded-lg cursor-pointer hover:opacity-90 transition-opacity border border-base-300"
            onclick="window.open('${url}', '_blank')"
            loading="lazy"
          />
        </div>
      `
    )

    // Twitter/X embeds (basic preview)
    processed = processed.replace(
      /https?:\/\/(?:twitter\.com|x\.com)\/\w+\/status\/(\d+)/g,
      (match, tweetId) => `
        <div class="tweet-embed my-4 p-4 border border-primary/30 rounded-lg bg-base-200/50 not-prose">
          <div class="flex items-center gap-2 mb-2">
            <svg class="w-5 h-5 text-primary" fill="currentColor" viewBox="0 0 24 24">
              <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/>
            </svg>
            <span class="font-semibold text-sm">Post on X</span>
          </div>
          <a href="${match}" target="_blank" rel="noopener" class="link link-primary text-sm">
            View post →
          </a>
        </div>
      `
    )

    return processed
  }
</script>

<div class="prose prose-sm md:prose-base max-w-none prose-code:bg-base-300 prose-code:text-base-content prose-code:px-2 prose-code:py-1 prose-code:rounded prose-pre:bg-base-300 prose-pre:border prose-pre:border-base-200">
  {@html html}
</div>

<style>
  :global(.hljs) {
    background: transparent !important;
    color: inherit;
  }

  :global(.hljs-attr),
  :global(.hljs-attribute) {
    color: #92c47d;
  }

  :global(.hljs-string) {
    color: #6da3c8;
  }

  :global(.hljs-number) {
    color: #f9ab56;
  }

  :global(.hljs-literal) {
    color: #f9ab56;
  }

  :global(.hljs-meta),
  :global(.hljs-meta .hljs-string) {
    color: #999;
  }

  :global(.hljs-code) {
    color: #d4d4d4;
  }

  :global(.hljs-symbol) {
    color: #f92672;
  }

  :global(.hljs-bullet) {
    color: #f92672;
  }

  :global(.hljs-title),
  :global(.hljs-section) {
    color: #92c47d;
  }

  :global(.hljs-keyword) {
    color: #66d9ef;
  }

  :global(.hljs-selector-tag) {
    color: #f92672;
  }
</style>
