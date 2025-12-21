# Svelte + Phoenix LiveView YouTube Embed Component

This document describes a small reusable **Svelte** component that wraps the **YouTube IFrame Player API**, and how to integrate it with **Phoenix LiveView** via `live_svelte`.

---

## 1. File Structure

Example structure inside your Phoenix `assets` directory:

```text
assets/
  js/
    svelte/
      lib/
        youtube/
          YouTubePlayer.svelte
      app.js              // live_svelte bootstrap
```

You can adjust paths to match your setup; the important part is having `YouTubePlayer.svelte` under some stable import path.

---

## 2. Core Component: `YouTubePlayer.svelte`

This component:

- Loads the YouTube IFrame API script once
- Creates the player instance
- Exposes props for configuration and external control
- Emits Svelte events for player state changes

```svelte
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

  function ensureYouTubeScript(): Promise<void> {
    return new Promise((resolve, reject) => {
      if ((window as any).YT && (window as any).YT.Player) {
        scriptLoaded = true;
        return resolve();
      }

      const existing = document.querySelector(`script[src="${YT_SRC}"]`);
      if (existing) {
        (window as any).onYouTubeIframeAPIReady = () => {
          scriptLoaded = true;
          resolve();
        };
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

<div class="w-full h-full">
  <div bind:this={container}></div>
</div>
```

### Props

- `videoId: string` – YouTube video ID
- `startSeconds?: number` – optional start time
- `autoplay?: boolean`
- `controls?: boolean`
- `rel?: boolean`
- `modestBranding?: boolean`
- `loop?: boolean`

### External control props

Controlled by parent via changing values:

- `playTrigger: number | null`  
- `pauseTrigger: number | null`  
- `seekToSeconds: number | null`  

You typically increment `playTrigger` / `pauseTrigger` from the parent to trigger play/pause.

### Events

Emitted events:

- `ready` – `{ duration }`
- `stateChange` – `{ state, currentTime, duration }`
- `play`
- `pause`
- `ended`
- `error` – `{ code }`

---

## 3. Plain Svelte Usage Example

```svelte
<script lang="ts">
  import YouTubePlayer from "./lib/youtube/YouTubePlayer.svelte";

  let playTick = 0;
  let pauseTick = 0;
  let seekTo: number | null = null;

  function play() {
    playTick += 1;
  }

  function pause() {
    pauseTick += 1;
  }

  function jumpTo(seconds: number) {
    seekTo = seconds;
  }
</script>

<YouTubePlayer
  videoId="dQw4w9WgXcQ"
  autoplay={false}
  controls={true}
  rel={false}
  modestBranding={true}
  loop={false}
  playTrigger={playTick}
  pauseTrigger={pauseTick}
  seekToSeconds={seekTo}
  on:ready={(e) => console.log("ready", e.detail)}
  on:stateChange={(e) => console.log("state", e.detail)}
/>

<div class="controls">
  <button on:click={play}>Play</button>
  <button on:click={pause}>Pause</button>
  <button on:click={() => jumpTo(60)}>Jump to 1:00</button>
</div>
```

---

## 4. Using with Phoenix LiveView via `live_svelte`

In your `*.html.heex` LiveView template, you can embed the Svelte component using `live_svelte`’s `svelte` component:

```elixir
<.svelte
  name="YouTubePlayer"
  props={
    %{
      videoId: @video_id,
      autoplay: false,
      controls: true,
      rel: false,
      modestBranding: true,
      loop: false,
      playTrigger: @play_tick,
      pauseTrigger: @pause_tick,
      seekToSeconds: @seek_to
    }
  }
  events={
    %{
      "ready" => "yt_ready",
      "stateChange" => "yt_state_change",
      "play" => "yt_play",
      "pause" => "yt_pause",
      "ended" => "yt_ended"
    }
  }
/>
```

### LiveView Module Example

```elixir
defmodule YourAppWeb.LessonLive.Show do
  use YourAppWeb, :live_view

  alias YourApp.Courses

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    lesson = Courses.get_lesson!(id)

    {:ok,
     socket
     |> assign(:lesson, lesson)
     |> assign(:video_id, lesson.youtube_video_id)
     |> assign(:play_tick, 0)
     |> assign(:pause_tick, 0)
     |> assign(:seek_to, nil)
     |> assign(:video_duration, nil)}
  end

  @impl true
  def handle_event("yt_ready", %{"duration" => duration}, socket) do
    {:noreply, assign(socket, :video_duration, duration)}
  end

  def handle_event("yt_state_change", %{"state" => state, "currentTime" => t}, socket) do
    # state: -1, 0, 1, 2, 3, 5
    # use this for analytics or UI reactions
    {:noreply, socket}
  end

  def handle_event("play_clicked", _params, socket) do
    {:noreply, update(socket, :play_tick, &(&1 + 1))}
  end

  def handle_event("pause_clicked", _params, socket) do
    {:noreply, update(socket, :pause_tick, &(&1 + 1))}
  end

  def handle_event("seek_to", %{"seconds" => seconds}, socket) do
    {:noreply, assign(socket, :seek_to, seconds)}
  end
end
```

Now LiveView controls the YouTube player via reactive assigns, and the Svelte component reports back via LiveView events.

---

## 5. Optional “Library” Export

You can add a small index barrel to treat this as a mini internal library.

```ts
// assets/js/svelte/lib/youtube/index.ts
export { default as YouTubePlayer } from "./YouTubePlayer.svelte";
```

Then in Svelte files:

```svelte
<script lang="ts">
  import { YouTubePlayer } from "$lib/youtube";
</script>
```

---

## 6. Design Notes & Caveats

- Do not spam LiveView with high-frequency state updates; use `stateChange` and coarse checkpoints instead of sending every second.
- Let Svelte handle local player UI details; use LiveView for higher-level control and analytics.
- For heavy analytics, consider batching in JS and sending aggregated data to the backend, instead of hammering the LiveView process.

This gives you a clean, reusable Svelte wrapper for the YouTube IFrame Player API that plugs nicely into Phoenix LiveView via `live_svelte`.
