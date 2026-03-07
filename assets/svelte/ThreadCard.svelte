<script>
  export let id = ""
  export let title = ""
  export let body = ""
  export let author = {}
  export let score = 0
  export let comment_count = 0
  export let view_count = 0
  export let created_at = null
  export let user_vote = null
  export let is_saved = false
  export let is_subscribed = false
  export let is_unread = false
  export let is_solved = false
  export let is_locked = false
  export let is_pinned = false

  // live is automatically available from LiveSvelte
  export let live

  function formatDate(date) {
    if (!date) return ""
    const d = new Date(date)
    const now = new Date()
    const diffMs = now - d
    const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24))

    if (diffDays === 0) {
      const diffHours = Math.floor(diffMs / (1000 * 60 * 60))
      if (diffHours === 0) return "now"
      return `${diffHours}h ago`
    }
    if (diffDays === 1) return "yesterday"
    if (diffDays < 7) return `${diffDays}d ago`

    return d.toLocaleDateString("en-US", {
      year: "numeric",
      month: "short",
      day: "numeric"
    })
  }

  import UMIcon from "./UMIcon.svelte"

  function handleVote(value) {
    live.pushEvent("vote", {
      target_type: "thread",
      target_id: id,
      value: String(value)
    })
  }

  function handleSave() {
    live.pushEvent("save_thread", { thread_id: id })
  }

  function handleSubscribe() {
    if (is_subscribed) {
      live.pushEvent("unsubscribe", { thread_id: id })
    } else {
      live.pushEvent("subscribe", { thread_id: id })
    }
  }
</script>

<div class="flex items-center gap-4 px-4 sm:px-5 py-4 hover:bg-base-200/30 transition-colors">
  <!-- Topic Column (flexible) -->
  <div class="flex-1 min-w-0">
    <a href="/forum/t/{id}" class="block group">
      <div class="flex items-center gap-2 flex-wrap">
        <h3 class="text-base font-semibold text-base-content group-hover:text-primary transition-colors truncate max-w-full">
          {title}
        </h3>
        {#if is_pinned}
          <span class="badge badge-info badge-xs gap-1 flex-shrink-0">
            <UMIcon name="arrow_up" className="w-3 h-3" />
            pinned
          </span>
        {/if}
        {#if is_locked}
          <span class="badge badge-warning badge-xs gap-1 flex-shrink-0">
            <UMIcon name="lock_closed" className="w-3 h-3" />
            locked
          </span>
        {/if}
        {#if is_solved}
          <span class="badge badge-success badge-xs gap-1 flex-shrink-0">
            <UMIcon name="check_circle" className="w-3 h-3" />
            solved
          </span>
        {/if}
        {#if is_unread}
          <span class="badge badge-info badge-xs flex-shrink-0">new</span>
        {/if}
      </div>
      <p class="text-sm text-base-content/60 mt-1 line-clamp-1">
        {body}
      </p>
      <div class="flex items-center gap-2 text-xs text-base-content/50 mt-2 flex-wrap">
        <span>by {author?.username || "Unknown"}</span>
        <span class="hidden sm:inline">•</span>
        <span class="hidden sm:inline">{formatDate(created_at)}</span>
        <!-- Mobile: show replies inline -->
        <span class="sm:hidden">• {comment_count} {comment_count === 1 ? "reply" : "replies"}</span>
      </div>
    </a>
  </div>

  <!-- Replies Column (desktop only) -->
  <div class="hidden md:flex items-center justify-center w-12 flex-shrink-0">
    <span class="text-sm font-medium text-base-content/70">
      {comment_count}
    </span>
  </div>

  <!-- Views Column (desktop only) -->
  <div class="hidden md:flex items-center justify-center w-12 flex-shrink-0">
    <span class="text-sm font-medium text-base-content/70">
      {view_count}
    </span>
  </div>

  <!-- Activity Column (desktop only) -->
  <div class="hidden lg:flex items-center justify-end gap-3 w-28 flex-shrink-0">
    <!-- Vote Score -->
    <div class="flex flex-col items-center gap-1 min-w-12" role="group" aria-label="Vote on this topic">
      <button
        on:click|preventDefault={() => handleVote(1)}
        class="text-base-content/50 hover:text-primary transition-colors text-sm"
        class:text-primary={user_vote === 1}
        aria-label="Upvote"
        aria-pressed={user_vote === 1}
      >
        <UMIcon name="chevron_up" className="w-3 h-3" />
      </button>
      <span class="text-sm font-semibold text-base-content min-w-6 text-center" aria-label="{score} votes">
        {score}
      </span>
      <button
        on:click|preventDefault={() => handleVote(-1)}
        class="text-base-content/50 hover:text-error transition-colors text-sm"
        class:text-error={user_vote === -1}
        aria-label="Downvote"
        aria-pressed={user_vote === -1}
      >
        <UMIcon name="chevron_down" className="w-3 h-3" />
      </button>
    </div>

    <!-- Action Buttons -->
    <div class="flex items-center gap-2">
      <button
        on:click|preventDefault={handleSubscribe}
        class="btn btn-ghost btn-sm px-2 rounded"
        class:btn-primary={is_subscribed}
        aria-label={is_subscribed ? "Unsubscribe from notifications" : "Subscribe to notifications"}
        aria-pressed={is_subscribed}
      >
        <UMIcon name={is_subscribed ? "envelope_solid" : "envelope"} className="w-4 h-4" />
      </button>
      <button
        on:click|preventDefault={handleSave}
        class="btn btn-ghost btn-sm px-2 rounded"
        class:btn-primary={is_saved}
        aria-label={is_saved ? "Remove from saved" : "Save this topic"}
        aria-pressed={is_saved}
      >
        <UMIcon name={is_saved ? "bookmark_solid" : "bookmark"} className="w-4 h-4" />
      </button>
    </div>
  </div>
</div>
