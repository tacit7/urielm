<script>
  import VoteButtons from "./VoteButtons.svelte"
  import PostActions from "./PostActions.svelte"
  import MarkdownInput from "./MarkdownInput.svelte"

  export let comments = []
  export let current_user_id = null
  export let current_user_is_admin = false
  export let depth = 0

  // live is automatically available from LiveSvelte
  export let live

  const MAX_DEPTH = 8
  let replyingTo = null
  let replyText = ""
  let editingId = null
  let editText = ""
  let replyEditorRef = null
  let editEditorRef = null

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

  function handleReport(commentId) {
    const modal = document.getElementById(`report_comment_modal_${commentId}`)
    if (modal) {
      modal.showModal()
    }
  }

  function startReply(commentId) {
    replyingTo = commentId
    replyText = ""
  }

  function cancelReply() {
    replyingTo = null
    replyText = ""
  }

  function submitReply(parentId) {
    if (!replyText.trim()) return

    if (live) {
      live.pushEvent("create_comment", {
        body: replyText,
        parent_id: parentId
      })
    }

    // Clear draft after successful submission
    if (replyEditorRef?.clearDraft) {
      replyEditorRef.clearDraft()
    }

    replyText = ""
    replyingTo = null
  }

  function startEdit(commentId, body) {
    editingId = commentId
    editText = body
  }

  function cancelEdit() {
    editingId = null
    editText = ""
  }

  function submitEdit(commentId) {
    if (!editText.trim()) return

    if (live) {
      live.pushEvent("edit_comment", {
        id: commentId,
        body: editText
      })
    }

    // Clear draft after successful submission
    if (editEditorRef?.clearDraft) {
      editEditorRef.clearDraft()
    }

    editingId = null
    editText = ""
  }

  function canEdit(authorId) {
    if (!current_user_id) return false
    return current_user_id === authorId || current_user_is_admin
  }
</script>

<div class="space-y-3">
  {#if comments && comments.length > 0}
    {#each comments as comment (comment.id)}
      <div class="p-4">
        <div>
          <div class="flex justify-between items-start gap-4">
            <div class="flex-1">
              <div class="flex items-center gap-3 mb-2">
                {#if comment.author?.avatar_url}
                  <img
                    src={comment.author.avatar_url}
                    alt={comment.author?.username || "User"}
                    class="w-8 h-8 rounded-full object-cover"
                  />
                {:else}
                  <div class="w-8 h-8 rounded-full bg-base-300 flex items-center justify-center text-xs font-bold">
                    {(comment.author?.username || "U")[0].toUpperCase()}
                  </div>
                {/if}
                <div>
                  <p class="font-semibold text-base-content text-sm">
                    {comment.author?.username || "Unknown"}
                  </p>
                  <span class="text-xs text-base-content/50">
                    {formatDate(comment.inserted_at)}
                  </span>
                </div>
              </div>

              {#if editingId === comment.id}
                <div class="mb-3 space-y-2">
                  <MarkdownInput
                    bind:value={editText}
                    bind:this={editEditorRef}
                    placeholder="Edit your comment..."
                    minHeight="150px"
                    draftKey={`draft_comment_edit_${comment.id}`}
                  />
                  <div class="flex gap-2 justify-end">
                    <button
                      on:click={cancelEdit}
                      class="btn btn-sm btn-ghost"
                    >
                      Cancel
                    </button>
                    <button
                      on:click={() => submitEdit(comment.id)}
                      disabled={!editText.trim()}
                      class="btn btn-sm btn-primary"
                    >
                      Save
                    </button>
                  </div>
                </div>
              {:else}
                <p class="text-base-content mb-3">
                  {comment.body}
                  {#if comment.edited_at}
                    <span class="text-xs text-base-content/50 ml-2">(edited)</span>
                  {/if}
                </p>
              {/if}

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

            <div class="flex gap-2">
              {#if canEdit(comment.author?.id) && editingId !== comment.id}
                <button
                  on:click={() => startEdit(comment.id, comment.body)}
                  class="btn btn-xs btn-ghost text-info"
                >
                  Edit
                </button>
              {/if}
              {#if canDelete(comment.author?.id)}
                <button
                  on:click={() => handleDelete(comment.id)}
                  class="btn btn-xs btn-ghost text-error"
                >
                  Delete
                </button>
              {/if}
              {#if current_user_id}
                <button
                  on:click={() => handleReport(comment.id)}
                  class="btn btn-xs btn-ghost text-warning"
                  title="Report this comment"
                >
                  Report
                </button>
              {/if}
            </div>
          </div>

          <!-- Post Actions (reply, like, copy link) -->
          {#if current_user_id}
            <PostActions
              postId={comment.id}
              liked={false}
              likeCount={0}
              canReply={depth < MAX_DEPTH}
              {live}
            />
          {/if}

          <!-- Reply form -->
          {#if replyingTo === comment.id}
            <div class="mt-4 pt-4 border-t border-base-300">
              <div class="space-y-2">
                <MarkdownInput
                  bind:value={replyText}
                  bind:this={replyEditorRef}
                  placeholder="Write a reply..."
                  minHeight="150px"
                  draftKey={`draft_comment_reply_${comment.id}`}
                />
                <div class="flex gap-2 justify-end">
                  <button
                    on:click={cancelReply}
                    class="btn btn-sm btn-ghost"
                  >
                    Cancel
                  </button>
                  <button
                    on:click={() => submitReply(comment.id)}
                    disabled={!replyText.trim()}
                    class="btn btn-sm btn-primary"
                  >
                    Reply
                  </button>
                </div>
              </div>
            </div>
          {/if}

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
