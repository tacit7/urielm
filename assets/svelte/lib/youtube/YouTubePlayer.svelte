<script lang="ts">
  import { onMount, onDestroy, createEventDispatcher } from "svelte";

  const YT_SRC = "https://www.youtube.com/iframe_api";

  const dispatcher = createEventDispatcher();

  // Props
  export let videoId: string;
  export let startSeconds: number | null = null;
  export let autoplay: boolean = false;
  export let controls: boolean = true;
  export let rel: boolean = false;
  export let modestBranding: boolean = true;
  export let loop: boolean = false;

  // External control props
  export let playTrigger: number | null = null;
  export let pauseTrigger: number | null = null;
  export let seekToSeconds: number | null = null;

  let container: HTMLDivElement;
  let player: any;
  let playerReady = false;
  let scriptLoaded = false;
  let destroyed = false;
  let playerId = `yt-player-${Math.random().toString(36).substr(2, 9)}`;

  function ensureYouTubeScript(): Promise<void> {
    return new Promise((resolve, reject) => {
      if ((window as any).YT && (window as any).YT.Player) {
        scriptLoaded = true;
        return resolve();
      }

      const existing = document.querySelector(`script[src="${YT_SRC}"]`);
      if (existing) {
        const checkReady = setInterval(() => {
          if ((window as any).YT && (window as any).YT.Player) {
            scriptLoaded = true;
            clearInterval(checkReady);
            resolve();
          }
        }, 100);
        return;
      }

      const tag = document.createElement("script");
      tag.src = YT_SRC;
      tag.async = true;

      (window as any).onYouTubeIframeAPIReady = () => {
        scriptLoaded = true;
        resolve();
      };

      tag.onerror = (err) => reject(err);

      document.head.appendChild(tag);
    });
  }

  function createPlayer() {
    if (!scriptLoaded || !container || !videoId || destroyed) return;

    const YT = (window as any).YT;

    player = new YT.Player(container, {
      width: "100%",
      height: "100%",
      videoId,
      playerVars: {
        autoplay: autoplay ? 1 : 0,
        controls: controls ? 1 : 0,
        rel: rel ? 1 : 0,
        modestbranding: modestBranding ? 1 : 0,
        loop: loop ? 1 : 0,
        playlist: loop ? videoId : undefined,
        start: startSeconds ?? undefined
      },
      events: {
        onReady: onPlayerReady,
        onStateChange: onPlayerStateChange,
        onError: onPlayerError
      }
    });
  }

  function onPlayerReady(event: any) {
    playerReady = true;
    dispatcher("ready", { duration: player.getDuration?.() });

    if (autoplay) {
      player.playVideo();
    }
  }

  function onPlayerStateChange(event: any) {
    const state = event.data;

    dispatcher("stateChange", {
      state,
      currentTime: safeGetCurrentTime(),
      duration: safeGetDuration()
    });

    if (state === 1) dispatcher("play");
    if (state === 2) dispatcher("pause");
    if (state === 0) dispatcher("ended");
  }

  function onPlayerError(event: any) {
    dispatcher("error", { code: event.data });
  }

  function safeGetCurrentTime(): number | null {
    try {
      return player?.getCurrentTime ? player.getCurrentTime() : null;
    } catch (_) {
      return null;
    }
  }

  function safeGetDuration(): number | null {
    try {
      return player?.getDuration ? player.getDuration() : null;
    } catch (_) {
      return null;
    }
  }

  // React to external control props
  $: if (playerReady && playTrigger !== null) {
    player.playVideo();
  }

  $: if (playerReady && pauseTrigger !== null) {
    player.pauseVideo();
  }

  $: if (playerReady && seekToSeconds !== null) {
    player.seekTo(seekToSeconds, true);
  }

  onMount(async () => {
    await ensureYouTubeScript();
    createPlayer();
  });

  onDestroy(() => {
    destroyed = true;
    try {
      player?.destroy?.();
    } catch (_) {}
  });
</script>

<div bind:this={container} {playerId} style="width: 100%; height: 100%;"></div>
