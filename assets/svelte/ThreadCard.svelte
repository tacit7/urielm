<script>
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

<div class="group grid grid-cols-[auto_1fr_auto] md:grid-cols-[auto_1fr_56px_56px_72px] items-center gap-x-4 px-4 py-3 hover:bg-base-200/40 transition-colors border-t border-base-300/50 first:border-t-0">

  <!-- Unread indicator -->
  <div class="w-2 flex items-center justify-center flex-shrink-0">
    {#if is_unread}
      <span class="w-1.5 h-1.5 rounded-full bg-primary flex-shrink-0" title="Unread"></span>
    {/if}
  </div>

  <!-- Topic column -->
  <div class="min-w-0 block">
    <a href="/forum/t/{id}" class="block">
      <div class="flex items-center gap-2 flex-wrap">
        {#if is_pinned}
          <span class="inline-flex items-center gap-0.5 text-xs font-mono text-info font-semibold">↑ pinned</span>
        {/if}
        <span class="font-semibold text-sm text-base-content group-hover:text-primary transition-colors line-clamp-1 leading-snug">
          {title}
        </span>
        {#if is_solved}
          <span class="badge badge-success badge-xs">solved</span>
        {/if}
        {#if is_locked}
          <span class="badge badge-warning badge-xs">locked</span>
        {/if}
      </div>
    </a>
    <div class="flex items-center gap-2 mt-0.5 text-xs text-base-content/40 font-mono">
      <span>{author?.username || "unknown"}</span>
      {#if board}
        <span class="text-base-content/20">·</span>
        <a href="/forum/b/{board.slug}" class="hover:text-primary transition-colors">
          {board.name}
        </a>
      {/if}
    </div>
  </div>

  <!-- Replies (desktop) -->
  <div class="hidden md:flex flex-col items-center justify-center flex-shrink-0">
    <span class="text-sm font-mono text-base-content/70 tabular-nums">{comment_count}</span>
  </div>

  <!-- Views (desktop) -->
  <div class="hidden md:flex flex-col items-center justify-center flex-shrink-0">
    <span class="text-sm font-mono text-base-content/70 tabular-nums">{formatViews(view_count)}</span>
  </div>

  <!-- Activity + actions -->
  <div class="flex flex-col items-end gap-1 flex-shrink-0 min-w-[84px]">
    <span class="font-mono text-xs text-base-content/50 tabular-nums">{activityTime}</span>
    <!-- Always visible for touch; revealed on hover or keyboard focus on desktop -->
    <div class="flex items-center gap-1 opacity-100 md:opacity-0 md:group-hover:opacity-100 md:group-focus-within:opacity-100 transition-opacity">
      <button
        on:click|preventDefault={handleSave}
        class="inline-flex min-h-10 min-w-10 items-center justify-center rounded-lg text-base-content/45 hover:bg-base-200 hover:text-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/60 transition-colors"
        class:text-primary={is_saved}
        aria-label={is_saved ? "Remove saved thread" : "Save thread"}
        aria-pressed={is_saved}
        title={is_saved ? "Saved" : "Save"}
      >
        <svg class="h-4 w-4" fill={is_saved ? "currentColor" : "none"} stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z" />
        </svg>
      </button>
      <button
        on:click|preventDefault={handleSubscribe}
        class="inline-flex min-h-10 min-w-10 items-center justify-center rounded-lg text-base-content/45 hover:bg-base-200 hover:text-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/60 transition-colors"
        class:text-primary={is_subscribed}
        aria-label={is_subscribed ? "Unsubscribe from thread" : "Subscribe to thread"}
        aria-pressed={is_subscribed}
        title={is_subscribed ? "Unsubscribe" : "Subscribe"}
      >
        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
        </svg>
      </button>
    </div>
  </div>
</div>
