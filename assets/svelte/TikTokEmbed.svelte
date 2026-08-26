<script>
  /**
   * Responsive TikTok player using the official player/v1 iframe API.
   * Standard embeds retain context while fullscreen Shorts loop in place.
   */
  import { onMount } from 'svelte'
  import { buildTikTokPlayerUrl, getTikTokPlayerLayout } from '../js/tiktok_player.js'

  let { tiktokUrl = '', fullscreen = false } = $props()

  let playerError = $state(null)
  let playerUrl = $derived(buildTikTokPlayerUrl(tiktokUrl, { fullscreen }))
  let playerLayout = $derived(getTikTokPlayerLayout(fullscreen))

  function handlePlayerMessage(event) {
    if (event.origin !== 'https://www.tiktok.com') return
    if (!event.data || event.data['x-tiktok-player'] !== true) return

    if (event.data.type === 'onPlayerError' || event.data.type === 'onError') {
      playerError = 'TikTok could not play this video.'
    }
  }

  onMount(() => {
    window.addEventListener('message', handlePlayerMessage)
    return () => window.removeEventListener('message', handlePlayerMessage)
  })
</script>

{#if playerUrl && !playerError}
  <div class={playerLayout.containerClass}>
    <iframe
      src={playerUrl}
      title="TikTok video player"
      class={playerLayout.iframeClass}
      allow="autoplay; encrypted-media; fullscreen; picture-in-picture"
      allowfullscreen
      onerror={() => (playerError = 'TikTok could not load this video.')}
    ></iframe>
  </div>
{:else}
  <div class="flex h-full min-h-72 w-full items-center justify-center bg-black px-5 py-10 text-white">
    <div class="max-w-sm text-center" role="alert">
      <h2 class="text-lg font-bold">Video unavailable</h2>
      <p class="mt-2 text-sm leading-6 text-white/75">
        {playerError || 'This TikTok link is not supported by the embedded player.'}
      </p>
      {#if tiktokUrl}
        <a
          href={tiktokUrl}
          target="_blank"
          rel="noopener noreferrer"
          class="btn btn-primary mt-5 min-h-11"
        >
          Open on TikTok
        </a>
      {/if}
    </div>
  </div>
{/if}
