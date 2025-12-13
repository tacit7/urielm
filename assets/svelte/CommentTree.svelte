<script>
  import VoteButtons from "./VoteButtons.svelte"

  export let comments = []
  export let current_user_id = null
  export let current_user_is_admin = false
  export let depth = 0

  // live is automatically available from LiveSvelte
  export let live

  const MAX_DEPTH = 8

  function formatDate(date) {
    if (!date) return ""
    const d = new Date(date)
    return d.toLocaleDateString("en-US", {
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit"
    })
  }

  function handleDelete(commentId) {
    if (window.confirm("Delete this comment?")) {
      if (live) {
        live.pushEvent("delete_comment", { id: commentId })
      }
    }
  }

  function canDelete(authorId) {
    if (!current_user_id) return false
    return current_user_id === authorId || current_user_is_admin
  }
</script>

<div class="space-y-3">
  {#if comments && comments.length > 0}
    {#each comments as comment (comment.id)}
      <div class="card bg-base-200 border border-base-300">
        <div class="card-body p-4">
          <div class="flex justify-between items-start gap-4">
            <div class="flex-1">
              <div class="flex items-center gap-2 mb-2">
                <p class="font-semibold text-base-content">
                  {comment.author?.username || "Unknown"}
                </p>
                <span class="text-xs text-base-content/50">
                  {formatDate(comment.inserted_at)}
                </span>
              </div>

              <p class="text-base-content mb-3">
                {comment.body}
              </p>

              <div class="flex items-center gap-4">
                <VoteButtons
                  target_type="comment"
                  target_id={comment.id}
                  score={comment.score || 0}
                  user_vote={comment.user_vote}
                  {live}
                />
              </div>
            </div>

            {#if canDelete(comment.author?.id)}
              <button
                on:click={() => handleDelete(comment.id)}
                class="btn btn-xs btn-ghost text-error"
              >
                Delete
              </button>
            {/if}
          </div>

          <!-- Nested replies -->
          {#if comment.replies && comment.replies.length > 0 && depth < MAX_DEPTH}
            <div class="mt-4 ml-4 border-l-2 border-base-300 pl-4">
              <svelte:self
                comments={comment.replies}
                current_user_id={current_user_id}
                current_user_is_admin={current_user_is_admin}
                {live}
                depth={depth + 1}
              />
            </div>
          {/if}
        </div>
      </div>
    {/each}
  {:else}
    <p class="text-center text-base-content/50 py-8">
      No comments yet. Be the first to reply!
    </p>
  {/if}
</div>
