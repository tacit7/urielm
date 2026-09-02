<script>
  import MarkdownIt from 'markdown-it'
  import hljs from 'highlight.js'
  import DOMPurify from 'dompurify'
  import { processEmbeds } from '../js/markdown/embeds.js'

  let { content = '', enableEmbeds = false, localTimestampVideoId = null } = $props()
  let container = $state()

  // Configure DOMPurify to allow safe markdown tags but block XSS vectors
  const purifyConfig = {
    ALLOWED_TAGS: [
      'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
      'p', 'br', 'hr',
      'ul', 'ol', 'li',
      'blockquote', 'pre', 'code',
      'a', 'strong', 'em', 'del', 's', 'u',
      'table', 'thead', 'tbody', 'tr', 'th', 'td',
      'img', 'span', 'div',
      // Embed containers (only used when enableEmbeds=true)
      'iframe'
    ],
    ALLOWED_ATTR: [
      'href', 'src', 'alt', 'title', 'class', 'id',
      'target', 'rel',
      // For code highlighting
      'lang',
      // For iframes (YouTube embeds)
      'width', 'height', 'frameborder', 'allow', 'allowfullscreen'
    ],
    // Block javascript: and data: URLs
    ALLOWED_URI_REGEXP: /^(?:(?:https?|mailto|tel):|[^a-z]|[a-z+.-]+(?:[^a-z+.\-:]|$))/i,
    // Add rel="noopener noreferrer" to all links
    ADD_ATTR: ['target'],
    // Forbid dangerous protocols
    FORBID_ATTR: ['onerror', 'onload', 'onclick', 'onmouseover'],
  }

  const md = new MarkdownIt({
    linkify: true,
    highlight: (code, lang) => {
      if (lang && hljs.getLanguage(lang)) {
        try {
          return hljs.highlight(code, { language: lang }).html
        } catch (__) {}
      }

      return md.utils.escapeHtml(code)
    }
  })

  let html = $derived.by(() => {
    if (!content) return ''

    let rendered = md.render(content)
    if (enableEmbeds) {
      rendered = processEmbeds(rendered)
    }
    // Sanitize HTML to prevent XSS
    return DOMPurify.sanitize(rendered, purifyConfig)
  })

  function parseTimestampValue(value) {
    if (!value) return null

    const timestamp = value.replace(/^t=/, '').replace(/s$/, '')

    if (/^\d+$/.test(timestamp)) {
      return Number.parseInt(timestamp, 10)
    }

    const parts = timestamp.split(':').map((part) => Number.parseInt(part, 10))
    if (parts.some((part) => Number.isNaN(part))) return null

    if (parts.length === 2) {
      const [minutes, seconds] = parts
      if (seconds >= 60) return null
      return minutes * 60 + seconds
    }

    if (parts.length === 3) {
      const [hours, minutes, seconds] = parts
      if (minutes >= 60 || seconds >= 60) return null
      return hours * 3600 + minutes * 60 + seconds
    }

    return null
  }

  function parseTimestampLink(anchor) {
    const href = anchor.getAttribute('href') || ''

    if (href.startsWith('#t=')) {
      return {
        videoId: localTimestampVideoId,
        seconds: parseTimestampValue(href.slice(1))
      }
    }

    try {
      const url = new URL(href, window.location.href)
      const host = url.hostname.replace(/^www\./, '')
      let videoId = null

      if (host === 'youtube.com' && url.pathname === '/watch') {
        videoId = url.searchParams.get('v')
      } else if (host === 'youtu.be') {
        videoId = url.pathname.split('/').filter(Boolean)[0] || null
      }

      if (!videoId || (localTimestampVideoId && videoId !== localTimestampVideoId)) {
        return null
      }

      return {
        videoId,
        seconds: parseTimestampValue(url.searchParams.get('t') || url.hash.replace(/^#/, ''))
      }
    } catch (_) {
      return null
    }
  }

  function handleClick(event) {
    if (!localTimestampVideoId) return

    const anchor = event.target?.closest?.('a')
    if (!anchor || !container?.contains(anchor)) return

    const timestamp = parseTimestampLink(anchor)
    if (!timestamp || timestamp.seconds === null) return

    event.preventDefault()
    document.dispatchEvent(
      new CustomEvent('urielm:video-seek', {
        detail: {
          videoId: timestamp.videoId || localTimestampVideoId,
          seconds: timestamp.seconds,
          play: true,
          scroll: true
        }
      })
    )
  }

  function timestampLinks(node) {
    node.addEventListener('click', handleClick)

    return {
      destroy() {
        node.removeEventListener('click', handleClick)
      }
    }
  }
</script>

<div
  bind:this={container}
  use:timestampLinks
  class="prose prose-sm md:prose-base max-w-none prose-code:bg-base-300 prose-code:text-base-content prose-code:px-2 prose-code:py-1 prose-code:rounded prose-pre:bg-base-300 prose-pre:border prose-pre:border-base-200"
>
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
