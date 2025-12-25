<script>
  /**
   * TikTok video embed with vertical aspect ratio (9:16)
   *
   * Fetches embed HTML from TikTok's oEmbed API and renders it
   *
   * @param {string} tiktokUrl - TikTok video URL
   */
  import { onMount } from 'svelte'

  let { tiktokUrl = '' } = $props()

  let embedHtml = $state('')
  let loading = $state(true)
  let error = $state(null)

  function extractVideoId(url) {
    if (!url) return null
    const match = url.match(/tiktok\.com\/@[\w.-]+\/video\/(\d+)/)
    return match ? match[1] : null
  }

  let videoId = $derived(extractVideoId(tiktokUrl))

  onMount(async () => {
    if (!tiktokUrl) {
      loading = false
      error = 'No TikTok URL provided'
      return
    }

    try {
      const response = await fetch(
        `https://www.tiktok.com/oembed?url=${encodeURIComponent(tiktokUrl)}`
      )

      if (!response.ok) {
        throw new Error('Failed to fetch embed')
      }

      const data = await response.json()
      embedHtml = data.html
      loading = false

      // Load TikTok embed script after inserting HTML
      setTimeout(() => {
        const existingScript = document.querySelector(
          'script[src="https://www.tiktok.com/embed.js"]'
        )
        if (existingScript) {
          // Force re-render by removing and re-adding
          existingScript.remove()
        }
        const script = document.createElement('script')
        script.src = 'https://www.tiktok.com/embed.js'
        script.async = true
        document.body.appendChild(script)
      }, 100)
    } catch (err) {
      error = err.message
      loading = false
    }
  })
</script>

<div class="flex justify-center">
  <div class="w-full max-w-[325px]">
    {#if loading}
      <div
        class="bg-base-200 rounded-lg animate-pulse flex items-center justify-center"
        style="aspect-ratio: 9/16; min-height: 580px;"
      >
        <span class="loading loading-spinner loading-lg"></span>
      </div>
    {:else if error}
      <div class="alert alert-error">
        <span>Failed to load TikTok video: {error}</span>
      </div>
    {:else}
      <div class="tiktok-container" style="aspect-ratio: 9/16;">
        {@html embedHtml}
      </div>
    {/if}
  </div>
</div>

<style>
  .tiktok-container :global(blockquote) {
    margin: 0;
    max-width: 100% !important;
  }

  .tiktok-container :global(iframe) {
    border-radius: 0.5rem;
  }
</style>
