<script>
  export let id = ""
  export let title = ""
  export let body = ""
  export let author = {}
  export let score = 0
  export let comment_count = 0
  export let created_at = null
  export let user_vote = null

  // live is automatically available from LiveSvelte
  export let live

  function formatDate(date) {
    if (!date) return ""
    const d = new Date(date)
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
</script>

<a href="/forum/t/{id}" class="card bg-base-200 border border-base-300 hover:shadow-lg transition-shadow">
  <div class="card-body">
    <h3 class="card-title text-base-content text-lg">
      {title}
    </h3>

    <p class="text-sm text-base-content/60 line-clamp-2">
      {body}
    </p>

    <div class="flex items-center justify-between pt-4 border-t border-base-300">
      <div class="flex items-center gap-4 text-xs text-base-content/50">
        <span>By {author?.username || "Unknown"}</span>
        <span>{formatDate(created_at)}</span>
      </div>

      <div class="flex items-center gap-4">
        <span class="text-xs text-base-content/50">
          {comment_count} {comment_count === 1 ? "comment" : "comments"}
        </span>

        <div class="flex items-center gap-1">
          <button
            on:click|preventDefault={() => handleVote(1)}
            class="btn btn-xs btn-ghost text-base-content/50 hover:text-primary"
            class:text-primary={user_vote === 1}
            title="Upvote"
          >
            ▲
          </button>
          <span class="text-sm font-medium text-base-content/70 min-w-8 text-center">
            {score}
          </span>
          <button
            on:click|preventDefault={() => handleVote(-1)}
            class="btn btn-xs btn-ghost text-base-content/50 hover:text-error"
            class:text-error={user_vote === -1}
            title="Downvote"
          >
            ▼
          </button>
        </div>
      </div>
    </div>
  </div>
</a>
