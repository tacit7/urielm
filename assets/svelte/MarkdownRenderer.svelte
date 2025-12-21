<script>
  import MarkdownIt from 'markdown-it'
  import hljs from 'highlight.js'
  import { processEmbeds } from '../js/markdown/embeds.js'

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
