<script>
  export let postId
  export let liked = false
  export let likeCount = 0
  export let is_saved = false
  export let canReply = true
  export let onReply = null
  export let live

  let isLoading = false
  let currentLiked = liked
  let currentCount = likeCount
  let currentSaved = is_saved

  async function toggleLike() {
    if (isLoading || !live) return

    // Optimistic UI update
    const wasLiked = currentLiked
    const oldCount = currentCount
    currentLiked = !currentLiked
    currentCount = currentLiked ? oldCount + 1 : oldCount - 1

    isLoading = true
    try {
      live.pushEvent('toggle_like', {
        target_type: 'comment',
        target_id: postId
      })
    } catch (e) {
      // Revert on error
      currentLiked = wasLiked
      currentCount = oldCount
      console.error('Failed to toggle like:', e)
    } finally {
      isLoading = false
    }
  }

  function handleReply() {
    if (onReply) {
      onReply()
    } else if (live) {
      live.pushEvent('reply_to_comment', {comment_id: postId})
    }
  }

  function handleBookmark() {
    if (!live) return
    currentSaved = !currentSaved
    live.pushEvent('save_comment', {comment_id: postId})
  }

  async function copyLink() {
    const permalink = `${window.location.origin}/forum/c/${postId}`
    try {
      await navigator.clipboard.writeText(permalink)
      // Show toast notification
      const event = new CustomEvent('show-toast', {
        detail: {message: 'Link copied to clipboard', type: 'success'}
      })
      window.dispatchEvent(event)
    } catch (e) {
      console.error('Failed to copy link:', e)
      const event = new CustomEvent('show-toast', {
        detail: {message: 'Failed to copy link', type: 'error'}
      })
      window.dispatchEvent(event)
    }
  }
</script>

<div class="ghost-actions-bar">
  <!-- Left: Reply button (text) -->
  <button
    on:click={handleReply}
    disabled={!canReply || isLoading}
    class="btn-ghost-icon"
    title="Reply to this comment"
  >
    <span class="hero hero-arrow-uturn-left"></span>
  </button>

  <!-- Right: Like and Copy buttons (icons with counts) -->
  <div class="flex items-center gap-1">
    <!-- Like button -->
    <button
      on:click={toggleLike}
      disabled={isLoading}
      class="btn-ghost-icon group"
      title={currentLiked ? 'Unlike' : 'Like'}
    >
      {#if currentLiked}
        <span class="hero hero-heart-solid text-error"></span>
      {:else}
        <span class="hero hero-heart"></span>
      {/if}
    </button>
    {#if currentCount > 0}
      <span class="text-xs text-base-content/50 font-medium min-w-6 text-right">
        {currentCount}
      </span>
    {/if}

    <!-- Bookmark button -->
    <button
      on:click={handleBookmark}
      disabled={isLoading}
      class="btn-ghost-icon"
      title={currentSaved ? 'Remove bookmark' : 'Bookmark comment'}
    >
      {#if currentSaved}
        <span class="hero hero-bookmark-solid text-warning"></span>
      {:else}
        <span class="hero hero-bookmark"></span>
      {/if}
    </button>

    <!-- Copy link button -->
    <button
      on:click={copyLink}
      disabled={isLoading}
      class="btn-ghost-icon"
      title="Copy link to this comment"
    >
      <span class="hero hero-link"></span>
    </button>
  </div>
</div>
