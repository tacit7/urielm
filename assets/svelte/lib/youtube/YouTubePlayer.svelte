<script lang="ts">
  const YT_SRC = "https://www.youtube.com/iframe_api";

  interface Props {
    videoId: string;
    startSeconds?: number | null;
    autoplay?: boolean;
    controls?: boolean;
    rel?: boolean;
    modestBranding?: boolean;
    loop?: boolean;
    shorts?: boolean;
    playTrigger?: number | null;
    pauseTrigger?: number | null;
    seekToSeconds?: number | null;
    onReady?: ((data: { duration: number | null }) => void) | null;
    onStateChange?: ((data: { state: number; currentTime: number | null; duration: number | null }) => void) | null;
    onPlay?: (() => void) | null;
    onPause?: (() => void) | null;
    onEnded?: (() => void) | null;
    onError?: ((data: { code: any }) => void) | null;
  }

  let {
    videoId,
    startSeconds = null,
    autoplay = false,
    controls = true,
    rel = false,
    modestBranding = true,
    loop = false,
    shorts = false,
    playTrigger = null,
    pauseTrigger = null,
    seekToSeconds = null,
    onReady = null,
    onStateChange = null,
    onPlay = null,
    onPause = null,
    onEnded = null,
    onError = null,
  }: Props = $props();

  let container = $state<HTMLDivElement>();
  let playerShell = $state<HTMLDivElement>();
  let player: any;
  let playerReady = $state(false);
  const playerId = `yt-player-${Math.random().toString(36).substr(2, 9)}`;

  function ensureYouTubeScript(): Promise<void> {
    return new Promise((resolve, reject) => {
      if ((window as any).YT && (window as any).YT.Player) {
        return resolve();
      }

      const existing = document.querySelector(`script[src="${YT_SRC}"]`);
      if (existing) {
        const checkReady = setInterval(() => {
          if ((window as any).YT && (window as any).YT.Player) {
            clearInterval(checkReady);
            resolve();
          }
        }, 100);
        return;
      }

      const tag = document.createElement("script");
      tag.src = YT_SRC;
      tag.async = true;
      (window as any).onYouTubeIframeAPIReady = () => resolve();
      tag.onerror = (err) => reject(err);
      document.head.appendChild(tag);
    });
  }

  function createPlayer() {
    if (!container || !videoId) return;

    const YT = (window as any).YT;

    player = new YT.Player(container, {
      width: "100%",
      height: "100%",
      videoId,
      playerVars: {
        autoplay: autoplay ? 1 : 0,
        controls: shorts ? 0 : (controls ? 1 : 0),
        rel: shorts ? 0 : (rel ? 1 : 0),
        modestbranding: shorts ? 1 : (modestBranding ? 1 : 0),
        fs: shorts ? 0 : 1,
        loop: loop ? 1 : 0,
        playlist: loop ? videoId : undefined,
        start: startSeconds ?? undefined,
      },
      events: {
        onReady: handlePlayerReady,
        onStateChange: handlePlayerStateChange,
        onError: handlePlayerError,
      },
    });
  }

  function handlePlayerReady(_event: any) {
    playerReady = true;
    onReady?.({ duration: safeGetDuration() });
    if (autoplay) player.playVideo();
  }

  function handlePlayerStateChange(event: any) {
    const state = event.data;
    onStateChange?.({ state, currentTime: safeGetCurrentTime(), duration: safeGetDuration() });
    if (state === 1) onPlay?.();
    if (state === 2) onPause?.();
    if (state === 0) onEnded?.();
  }

  function handlePlayerError(event: any) {
    onError?.({ code: event.data });
  }

  function safeGetCurrentTime(): number | null {
    try { return player?.getCurrentTime ? player.getCurrentTime() : null; } catch (_) { return null; }
  }

  function safeGetDuration(): number | null {
    try { return player?.getDuration ? player.getDuration() : null; } catch (_) { return null; }
  }

  function handleExternalSeek(event: Event) {
    const detail = (event as CustomEvent).detail || {};
    if (detail.videoId && detail.videoId !== videoId) return;
    if (typeof detail.seconds !== "number" || Number.isNaN(detail.seconds)) return;

    if (detail.scroll) {
      playerShell?.scrollIntoView?.({ behavior: "smooth", block: "center" });
    }

    if (!playerReady) return;

    player.seekTo(detail.seconds, true);
    if (detail.play) player.playVideo();
  }

  $effect(() => {
    if (playerReady && playTrigger !== null) player.playVideo();
  });

  $effect(() => {
    if (playerReady && pauseTrigger !== null) player.pauseVideo();
  });

  $effect(() => {
    if (playerReady && seekToSeconds !== null) player.seekTo(seekToSeconds, true);
  });

  $effect(() => {
    let active = true;
    document.addEventListener("urielm:video-seek", handleExternalSeek);
    ensureYouTubeScript().then(() => {
      if (active) createPlayer();
    });
    return () => {
      active = false;
      document.removeEventListener("urielm:video-seek", handleExternalSeek);
      try { player?.destroy?.(); } catch (_) { /* ignore */ }
    };
  });
</script>

{#if shorts}
  <div bind:this={playerShell} class="relative w-full" style="padding-bottom: 177.77%;">
    <div class="absolute inset-0">
      <div bind:this={container} id={playerId} style="width: 100%; height: 100%;"></div>
    </div>
  </div>
{:else}
  <div bind:this={playerShell} style="width: 100%; height: 100%;">
    <div bind:this={container} id={playerId} style="width: 100%; height: 100%;"></div>
  </div>
{/if}
