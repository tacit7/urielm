<script>
  export let target_type = "thread"
  export let target_id = ""
  export let score = 0
  export let user_vote = null

  // live is automatically available from LiveSvelte
  export let live

  function handleVote(value) {
    live.pushEvent("vote", {
      target_type,
      target_id,
      value: String(value)
    })
  }
</script>

<div class="flex items-center gap-2">
  <button
    on:click={() => handleVote(1)}
    class="btn btn-xs btn-ghost text-base-content/60 hover:text-primary transition-colors"
    class:text-primary={user_vote === 1}
    title="Upvote"
  >
    <span class="hero hero-hand-thumb-up text-lg"></span>
  </button>
  <span class="text-sm font-medium text-base-content min-w-6 text-center">
    {score}
  </span>
</div>
