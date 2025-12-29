<script>
  import { Star, ArrowRight } from 'lucide-svelte'

  export let upvotes = 0
  export let downvotes = 0
  export let savesCount = 0
  export let userVote = null  // 1, -1, or null
  export let userSaved = false
  export let promptId = null
  export let detailUrl = null
  export let live = null

  // Backwards compatibility
  export let likesCount = null
  export let userLiked = null
  $: effectiveUpvotes = likesCount !== null ? likesCount : upvotes
  $: effectiveUserVote = userLiked !== null ? (userLiked ? 1 : null) : userVote

  function handleVote(value) {
    if (live) {
      live.pushEvent('vote', { target_type: 'prompt', target_id: String(promptId), value: String(value) })
    }
  }

  function handleSave() {
    if (live) {
      live.pushEvent('toggle_save', { id: promptId })
    }
  }
</script>

<div class="flex gap-4 items-center">
  <!-- Thumbs up -->
  <button
    on:click={() => handleVote(1)}
    class="flex items-center gap-1.5 transition-colors {effectiveUserVote === 1 ? 'text-primary' : 'text-base-content/70 hover:text-primary'}"
    title="Like this prompt"
  >
    {#if effectiveUserVote === 1}
      <span class="hero hero-hand-thumb-up-solid text-xl"></span>
    {:else}
      <span class="hero hero-hand-thumb-up text-xl"></span>
    {/if}
    <span class="text-sm font-medium">{effectiveUpvotes}</span>
  </button>

  <!-- Thumbs down -->
  <button
    on:click={() => handleVote(-1)}
    class="flex items-center gap-1.5 transition-colors {effectiveUserVote === -1 ? 'text-error' : 'text-base-content/70 hover:text-error'}"
    title="Dislike this prompt"
  >
    {#if effectiveUserVote === -1}
      <span class="hero hero-hand-thumb-down-solid text-xl"></span>
    {:else}
      <span class="hero hero-hand-thumb-down text-xl"></span>
    {/if}
    <span class="text-sm font-medium">{downvotes}</span>
  </button>

  <!-- Save -->
  <button
    on:click={handleSave}
    class="flex items-center gap-1.5 transition-colors {userSaved ? 'text-warning' : 'text-base-content/70 hover:text-warning'}"
    title="Save this prompt"
  >
    <Star size={20} fill={userSaved ? 'currentColor' : 'none'} />
    <span class="text-sm font-medium">{savesCount}</span>
  </button>

  <slot />

  {#if detailUrl}
    <a
      href={detailUrl}
      class="flex items-center gap-1.5 text-base-content/70 hover:text-primary transition-colors"
      title="View full prompt with comments"
    >
      <ArrowRight size={20} />
    </a>
  {/if}
</div>
