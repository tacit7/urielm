<script>
  /**
   * YouTube video embed with responsive 16:9 aspect ratio
   *
   * Converts various YouTube URL formats to embed URL:
   * - https://www.youtube.com/watch?v=VIDEO_ID
   * - https://youtu.be/VIDEO_ID
   * - https://www.youtube.com/embed/VIDEO_ID
   *
   * @param {string} youtubeUrl - YouTube video URL in any format
   */
  let { youtubeUrl = '' } = $props()

  function extractVideoId(url) {
    if (!url) return null

    // Match various YouTube URL formats
    const patterns = [
      /(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})/,
      /youtube\.com\/shorts\/([a-zA-Z0-9_-]{11})/,
      /youtube\.com\/embed\/([a-zA-Z0-9_-]{11})/
    ]

    for (const pattern of patterns) {
      const match = url.match(pattern)
      if (match && match[1]) {
        return match[1]
      }
    }

    return null
  }

  let videoId = $derived(extractVideoId(youtubeUrl))
  let embedUrl = $derived(
    videoId
      ? `https://www.youtube.com/embed/${videoId}?rel=0&modestbranding=1`
      : null
  )
</script>

{#if embedUrl}
  <div class="relative w-full" style="padding-bottom: 56.25%;">
    <!-- 16:9 aspect ratio (9/16 = 0.5625 = 56.25%) -->
    <iframe
      src={embedUrl}
      title="YouTube video player"
      frameborder="0"
      loading="lazy"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
      referrerpolicy="strict-origin-when-cross-origin"
      allowfullscreen
      class="absolute top-0 left-0 w-full h-full rounded-lg"
    ></iframe>
  </div>
{:else}
  <div class="alert alert-error">
    <span>Invalid YouTube URL</span>
  </div>
{/if}
