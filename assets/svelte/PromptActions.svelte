<script>
  import { Heart, Star, ArrowRight } from 'lucide-svelte'

  export let likesCount = 0
  export let savesCount = 0
  export let userLiked = false
  export let userSaved = false
  export let promptId = null
  export let detailUrl = null
  export let live = null

  function handleLike() {
    if (live) {
      live.pushEvent('toggle_like', { id: promptId })
    }
  }

  function handleSave() {
    if (live) {
      live.pushEvent('toggle_save', { id: promptId })
    }
  }
</script>

<div class="flex gap-6 items-center">
  <button
    on:click={handleLike}
    class="flex items-center gap-2 text-base-content/70 hover:text-error transition-colors {userLiked ? 'text-error' : ''}"
    title="Like this prompt"
  >
    <Heart size={20} fill={userLiked ? 'currentColor' : 'none'} />
    <span class="text-sm font-medium">{likesCount}</span>
  </button>

  <button
    on:click={handleSave}
    class="flex items-center gap-2 text-base-content/70 hover:text-warning transition-colors {userSaved ? 'text-warning' : ''}"
    title="Save this prompt"
  >
    <Star size={20} fill={userSaved ? 'currentColor' : 'none'} />
    <span class="text-sm font-medium">{savesCount}</span>
  </button>

  <slot />

  {#if detailUrl}
    <a
      href={detailUrl}
      class="flex items-center gap-2 text-base-content/70 hover:text-primary transition-colors"
      title="View full prompt with comments"
    >
      <ArrowRight size={20} />
    </a>
  {/if}
</div>
