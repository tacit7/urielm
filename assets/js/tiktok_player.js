const TIKTOK_PLAYER_ORIGIN = "https://www.tiktok.com"

export function extractTikTokVideoId(tiktokUrl) {
  if (!tiktokUrl) return null

  try {
    const url = new URL(tiktokUrl)
    const validHost = url.hostname === "tiktok.com" || url.hostname.endsWith(".tiktok.com")

    if (!validHost) return null

    return url.pathname.match(/^\/@[\w.-]+\/video\/(\d+)\/?$/i)?.[1] ?? null
  } catch (_) {
    return null
  }
}

export function buildTikTokPlayerUrl(tiktokUrl, { fullscreen = false } = {}) {
  const videoId = extractTikTokVideoId(tiktokUrl)
  if (!videoId) return null

  const playerUrl = new URL(`/player/v1/${videoId}`, TIKTOK_PLAYER_ORIGIN)
  const options = {
    controls: 1,
    progress_bar: 1,
    play_button: 1,
    volume_control: 1,
    fullscreen_button: 1,
    timestamp: 1,
    loop: fullscreen ? 1 : 0,
    autoplay: 0,
    music_info: 1,
    description: 1,
    rel: 0,
    native_context_menu: 1,
    closed_caption: 1,
    muted: 0
  }

  for (const [name, value] of Object.entries(options)) {
    playerUrl.searchParams.set(name, String(value))
  }

  return playerUrl.toString()
}
