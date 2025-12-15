<script>
  export let id = ""
  export let title = ""
  export let body = ""
  export let author = {}
  export let score = 0
  export let comment_count = 0
  export let created_at = null
  export let user_vote = null
  export let is_saved = false
  export let is_subscribed = false

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

<div class="flex items-center justify-between px-5 py-4 hover:bg-base-200/30 transition-colors">
  <!-- Left: Thread Info -->
  <div class="flex-1 min-w-0">
    <a href="/forum/t/{id}" class="block group">
      <h3 class="text-base font-semibold text-base-content group-hover:text-primary transition-colors">
        {title}
      </h3>
      <p class="text-sm text-base-content/60 mt-1 line-clamp-1">
        {body}
      </p>
      <div class="flex items-center gap-3 text-xs text-base-content/50 mt-2">
        <span>by {author?.username || "Unknown"}</span>
        <span>•</span>
        <span>{formatDate(created_at)}</span>
      </div>
    </a>
  </div>

  <!-- Right: Stats -->
  <div class="flex items-center gap-6 ml-6 text-right flex-shrink-0">
    <!-- Replies Count -->
    <div class="flex flex-col items-end">
      <span class="text-sm font-semibold text-base-content">
        {comment_count}
      </span>
      <span class="text-xs text-base-content/50">
        {comment_count === 1 ? "Reply" : "Replies"}
      </span>
    </div>

    <!-- Vote Score -->
    <div class="flex flex-col items-center gap-1 min-w-12">
      <button
        on:click|preventDefault={() => handleVote(1)}
        class="text-base-content/50 hover:text-primary transition-colors"
        class:text-primary={user_vote === 1}
        title="Upvote"
      >
        ▲
      </button>
      <span class="text-sm font-semibold text-base-content">
        {score}
      </span>
      <button
        on:click|preventDefault={() => handleVote(-1)}
        class="text-base-content/50 hover:text-error transition-colors"
        class:text-error={user_vote === -1}
        title="Downvote"
      >
        ▼
      </button>
    </div>

    <!-- Action Buttons -->
    <div class="flex items-center gap-2">
      <button
        on:click|preventDefault={handleSubscribe}
        class="btn btn-ghost btn-sm px-2"
        class:btn-primary={is_subscribed}
        title={is_subscribed ? "Unsubscribe" : "Subscribe"}
      >
        <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
          <path d="M15 5H3c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V7c0-1.1-.9-2-2-2zm0 4l-7 4.5L3 9V7l7 4.5L15 7v2z" />
        </svg>
      </button>
      <button
        on:click|preventDefault={handleSave}
        class="btn btn-ghost btn-sm px-2"
        class:btn-primary={is_saved}
        title={is_saved ? "Unsave" : "Save"}
      >
        <svg class="w-4 h-4" fill={is_saved ? "currentColor" : "none"} stroke="currentColor" viewBox="0 0 24 24">
          <path d="M5 5a2 2 0 012-2h6a2 2 0 012 2v16l-8-4-8 4V5z" stroke-width="2" stroke-linejoin="round" stroke-linecap="round" />
        </svg>
      </button>
    </div>
  </div>
</div>
