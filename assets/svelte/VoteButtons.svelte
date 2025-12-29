<script>
  /**
   * YouTube-style thumbs up/down voting component
   *
   * @param {string} target_type - "video", "thread", "comment", etc.
   * @param {string} target_id - ID of the target
   * @param {number} upvotes - Number of upvotes
   * @param {number} downvotes - Number of downvotes
   * @param {number|null} user_vote - User's vote: 1 (up), -1 (down), or null
   * @param {string} layout - "horizontal" (default) or "vertical" (for shorts)
   * @param {string} size - "sm" (default) or "lg" (for shorts)
   */
  export let target_type = "thread"
  export let target_id = ""
  export let upvotes = 0
  export let downvotes = 0
  export let user_vote = null
  export let layout = "horizontal"
  export let size = "sm"

  // Backwards compatibility: if score is passed, use it as upvotes
  export let score = null
  $: effectiveUpvotes = score !== null ? score : upvotes

  // live is automatically available from LiveSvelte
  export let live

  function handleVote(value) {
    live.pushEvent("vote", {
      target_type,
      target_id,
      value: String(value)
    })
  }

  $: isVertical = layout === "vertical"
  $: isLarge = size === "lg"
  $: btnClass = isLarge ? "btn btn-ghost btn-circle" : "btn btn-xs btn-ghost"
  $: iconClass = isLarge ? "text-2xl" : "text-lg"
  $: countClass = isLarge ? "text-sm font-medium" : "text-sm font-medium"
</script>

<div class="flex items-center {isVertical ? 'flex-col gap-3' : 'gap-1'}">
  <!-- Upvote -->
  <div class="flex items-center {isVertical ? 'flex-col' : 'gap-1'}">
    <button
      on:click={() => handleVote(1)}
      class="{btnClass} transition-colors {user_vote === 1 ? 'text-primary' : 'text-base-content/60 hover:text-primary'}"
      title="Like"
      aria-label="Like"
    >
      {#if user_vote === 1}
        <span class="hero hero-hand-thumb-up-solid {iconClass}"></span>
      {:else}
        <span class="hero hero-hand-thumb-up {iconClass}"></span>
      {/if}
    </button>
    <span class="{countClass} text-base-content/80 min-w-4 text-center">
      {effectiveUpvotes}
    </span>
  </div>

  <!-- Separator (horizontal only) -->
  {#if !isVertical}
    <span class="text-base-content/30 mx-1">|</span>
  {/if}

  <!-- Downvote -->
  <div class="flex items-center {isVertical ? 'flex-col' : 'gap-1'}">
    <button
      on:click={() => handleVote(-1)}
      class="{btnClass} transition-colors {user_vote === -1 ? 'text-error' : 'text-base-content/60 hover:text-error'}"
      title="Dislike"
      aria-label="Dislike"
    >
      {#if user_vote === -1}
        <span class="hero hero-hand-thumb-down-solid {iconClass}"></span>
      {:else}
        <span class="hero hero-hand-thumb-down {iconClass}"></span>
      {/if}
    </button>
    <span class="{countClass} text-base-content/80 min-w-4 text-center">
      {downvotes}
    </span>
  </div>
</div>
