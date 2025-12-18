<script>
  import VoteButtons from "./VoteButtons.svelte"
  import PostActions from "./PostActions.svelte"
  import CommentTree from "./CommentTree.svelte"

  let {
    comments = [],
    current_user_id = null,
    current_user_is_admin = false,
    thread_author_id = null,
    solved_comment_id = null,
    depth = 0,
    live
  } = $props()

  const MAX_DEPTH = 8
  let replyingTo = $state(null)
  let replyText = $state("")
  let editingId = $state(null)
  let editText = $state("")

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

  function canMarkSolved() {
    if (!current_user_id) return false
    return current_user_id === thread_author_id || current_user_is_admin
  }

  function handleMarkSolved(commentId) {
    if (live) {
      live.pushEvent("mark_solved", { comment_id: commentId })
    }
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
                  <textarea
                    bind:value={editText}
                    placeholder="Edit your comment..."
                    class="textarea textarea-bordered w-full bg-base-200 text-base-content"
                    rows="4"
                  ></textarea>
                  <div class="flex gap-2 justify-end">
                    <button
                      onclick={cancelEdit}
                      class="btn btn-sm btn-ghost"
                    >
                      Cancel
                    </button>
                    <button
                      onclick={() => submitEdit(comment.id)}
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
              {#if canMarkSolved() && comment.id === solved_comment_id}
                <span class="badge badge-success badge-sm gap-1">
                  ✓ Solution
                </span>
              {/if}
              {#if canMarkSolved() && comment.id !== solved_comment_id && !solved_comment_id}
                <button
                  onclick={() => handleMarkSolved(comment.id)}
                  class="btn btn-xs btn-success btn-outline"
                  title="Mark as solution"
                >
                  ✓ Solution
                </button>
              {/if}
              {#if canEdit(comment.author?.id) && editingId !== comment.id}
                <button
                  onclick={() => startEdit(comment.id, comment.body)}
                  class="btn btn-xs btn-ghost text-info"
                >
                  Edit
                </button>
              {/if}
              {#if canDelete(comment.author?.id)}
                <button
                  onclick={() => handleDelete(comment.id)}
                  class="btn btn-xs btn-ghost text-error"
                >
                  Delete
                </button>
              {/if}
              {#if current_user_id}
                <button
                  onclick={() => handleReport(comment.id)}
                  class="btn btn-xs btn-ghost text-warning"
                  title="Report this comment"
                >
                  Report
                </button>
              {/if}
            </div>
          </div>

          <!-- Post Actions (reply, like, bookmark, copy link) -->
          {#if current_user_id}
            <PostActions
              postId={comment.id}
              liked={false}
              likeCount={0}
              is_saved={comment.is_saved || false}
              canReply={depth < MAX_DEPTH}
              onReply={() => startReply(comment.id)}
              {live}
            />
          {/if}

          <!-- Reply form -->
          {#if replyingTo === comment.id}
            <div class="mt-4 pt-4 border-t border-base-300">
              <div class="space-y-2">
                <textarea
                  bind:value={replyText}
                  placeholder="Write a reply..."
                  class="textarea textarea-bordered w-full bg-base-200 text-base-content"
                  rows="4"
                ></textarea>
                <div class="flex gap-2 justify-end">
                  <button
                    onclick={cancelReply}
                    class="btn btn-sm btn-ghost"
                  >
                    Cancel
                  </button>
                  <button
                    onclick={() => submitReply(comment.id)}
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
              <CommentTree
                comments={comment.replies}
                current_user_id={current_user_id}
                current_user_is_admin={current_user_is_admin}
                thread_author_id={thread_author_id}
                solved_comment_id={solved_comment_id}
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
