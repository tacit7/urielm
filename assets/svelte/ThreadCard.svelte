<script>
  import UMIcon from "./UMIcon.svelte"
  import { handleVote as pushVote } from "../js/voteUtils.js"

  export let id = ""
  export let title = ""
  export let author = {}
  export let score = 0
  export let comment_count = 0
  export let view_count = 0
  export let created_at = null
  export let updated_at = null
  export let user_vote = null
  export let is_saved = false
  export let is_subscribed = false
  export let is_unread = false
  export let is_solved = false
  export let is_locked = false
  export let is_pinned = false

  export let board = null

  export let live

  function relativeTime(date) {
    if (!date) return ""
    const d = new Date(date)
    const now = new Date()
    const diff = Math.floor((now - d) / 1000)

    if (diff < 60) return "now"
    if (diff < 3600) return `${Math.floor(diff / 60)}m`
    if (diff < 86400) return `${Math.floor(diff / 3600)}h`
    if (diff < 604800) return `${Math.floor(diff / 86400)}d`
    if (diff < 2592000) return `${Math.floor(diff / 604800)}w`
    return `${Math.floor(diff / 2592000)}mo`
  }

  function formatViews(n) {
    if (n >= 1000) return `${(n / 1000).toFixed(n >= 10000 ? 0 : 1)}k`
    return String(n)
  }

  function handleVote(value) {
    pushVote(live, "thread", id, value)
  }

  function handleSave() {
    live.pushEvent("save_thread", { thread_id: id })
  }

  function handleSubscribe() {
    live.pushEvent(is_subscribed ? "unsubscribe" : "subscribe", { thread_id: id })
  }

  $: activityTime = relativeTime(updated_at || created_at)
  $: initials = (author?.username || "?").charAt(0).toUpperCase()
</script>

<article class="group grid grid-cols-1 items-start gap-x-3 gap-y-2 border-t border-base-300/45 px-3 py-2.5 transition-colors first:border-t-0 hover:bg-base-200/45 sm:grid-cols-[minmax(0,1fr)_auto] md:grid-cols-[minmax(0,1fr)_64px_64px_92px] md:items-center md:px-4">
  <div class="flex min-w-0 items-start gap-3">
    <div class="relative mt-0.5 flex size-8 shrink-0 items-center justify-center rounded-full bg-base-300 text-xs font-black text-base-content/60">
      {initials}
      {#if is_unread}
        <span class="absolute -right-0.5 -top-0.5 size-2 rounded-full bg-primary ring-2 ring-base-100" title="Unread"></span>
      {/if}
    </div>

    <div class="min-w-0 flex-1">
      <a href="/forum/t/{id}" class="block rounded-sm focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary">
        <div class="flex min-w-0 items-center gap-1.5">
          {#if is_pinned}
            <span class="inline-flex shrink-0 items-center text-xs font-bold text-info" title="Pinned">↑</span>
          {/if}
          <span class="line-clamp-1 text-[0.92rem] font-semibold leading-snug text-base-content transition-colors group-hover:text-primary">
            {title}
          </span>
        </div>
      </a>

      <div class="mt-1 flex min-w-0 flex-wrap items-center gap-x-2 gap-y-1 text-[0.72rem] leading-none text-base-content/45">
        <span class="truncate font-medium">{author?.username || "unknown"}</span>
        {#if board}
          <span class="text-base-content/20">·</span>
          <a href="/forum/b/{board.slug}" class="truncate font-medium text-base-content/55 transition-colors hover:text-primary">
            {board.name}
          </a>
        {/if}
        {#if is_solved}
          <span class="badge badge-success badge-xs h-4 min-h-4 px-1.5 text-[0.625rem]">solved</span>
        {/if}
        {#if is_locked}
          <span class="badge badge-warning badge-xs h-4 min-h-4 px-1.5 text-[0.625rem]">locked</span>
        {/if}
      </div>

      <div class="mt-2 flex items-center gap-3 text-[0.7rem] font-medium text-base-content/40 md:hidden">
        <span><span class="tabular-nums text-base-content/60">{comment_count}</span> replies</span>
        <span><span class="tabular-nums text-base-content/60">{formatViews(view_count)}</span> views</span>
      </div>
    </div>
  </div>

  <div class="hidden flex-col items-center justify-center md:flex">
    <span class="font-mono text-sm text-base-content/70 tabular-nums">{comment_count}</span>
  </div>

  <div class="hidden flex-col items-center justify-center md:flex">
    <span class="font-mono text-sm text-base-content/60 tabular-nums">{formatViews(view_count)}</span>
  </div>

  <div class="ml-11 flex min-w-0 items-center justify-between gap-2 sm:ml-0 sm:min-w-[4.75rem] sm:flex-col sm:items-end sm:gap-1">
    <span class="font-mono text-xs text-base-content/50 tabular-nums">{activityTime}</span>
    <div class="flex items-center gap-0.5 opacity-100 transition-opacity md:opacity-0 md:group-hover:opacity-100 md:group-focus-within:opacity-100">
      <button
        on:click|preventDefault={handleSave}
        class="inline-flex min-h-10 min-w-10 items-center justify-center rounded-lg text-base-content/45 transition-colors hover:bg-base-200 hover:text-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/60 md:min-h-8 md:min-w-8"
        class:text-primary={is_saved}
        aria-label={is_saved ? "Remove saved thread" : "Save thread"}
        aria-pressed={is_saved}
        title={is_saved ? "Saved" : "Save"}
      >
        <UMIcon name={is_saved ? "hero-bookmark-solid" : "hero-bookmark"} className="size-4" />
      </button>
      <button
        on:click|preventDefault={handleSubscribe}
        class="inline-flex min-h-10 min-w-10 items-center justify-center rounded-lg text-base-content/45 transition-colors hover:bg-base-200 hover:text-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/60 md:min-h-8 md:min-w-8"
        class:text-primary={is_subscribed}
        aria-label={is_subscribed ? "Unsubscribe from thread" : "Subscribe to thread"}
        aria-pressed={is_subscribed}
        title={is_subscribed ? "Unsubscribe" : "Subscribe"}
      >
        <UMIcon name="hero-bell" className="size-4" />
      </button>
    </div>
  </div>
</article>
