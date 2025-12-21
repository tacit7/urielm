<script>
  import VoteButtons from "./VoteButtons.svelte"
  import PostActions from "./PostActions.svelte"
  import CommentTree from "./CommentTree.svelte"
  import ReplyComposer from "./ReplyComposer.svelte"

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
  let isComposerOpen = $state(false)
  let composerParentId = $state(null)

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
    if (live) {
      live.pushEvent("open_report_comment", { comment_id: commentId })
    }
  }

  function startReply(commentId) {
    composerParentId = commentId
    replyText = ""
    isComposerOpen = true
  }

  function cancelReply() {
    isComposerOpen = false
    composerParentId = null
    replyText = ""
  }

  function submitReply(text) {
    if (!text.trim()) return

    if (live) {
      live.pushEvent("create_comment", {
        body: text,
        parent_id: composerParentId
      })
    }

    isComposerOpen = false
    composerParentId = null
    replyText = ""
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
                <div class="mb-3">
                  <ReplyComposer
                    isOpen={true}
                    bind:replyText={editText}
                    placeholder="Edit your comment..."
                    onSubmit={() => submitEdit(comment.id)}
                    onDiscard={cancelEdit}
                    submitLabel="Save"
                  />
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

            <!-- Action buttons - Discourse style -->
            <div class="flex items-center justify-between mt-3 pb-3">
              <!-- Vote on left -->
              <div class="flex items-center gap-2 text-base-content/60">
                <button class="btn btn-ghost btn-xs btn-square" title="Like">
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 10h4.764a2 2 0 011.789 2.894l-3.5 7A2 2 0 0115.263 21h-4.017c-.163 0-.326-.02-.485-.06L7 20m7-10V5a2 2 0 00-2-2h-.095c-.5 0-.905.405-.905.905 0 .714-.211 1.412-.608 2.006L7 11v9m7-10h-2M7 20H5a2 2 0 01-2-2v-6a2 2 0 012-2h2.5"/>
                  </svg>
                </button>
                <span class="text-sm">0</span>
              </div>

              <!-- Actions on right -->
              <div class="flex items-center gap-1">
                {#if canEdit(comment.author?.id) && editingId !== comment.id}
                  <button
                    onclick={() => startEdit(comment.id, comment.body)}
                    class="btn btn-ghost btn-xs text-base-content/60 hover:text-base-content"
                  >
                    Edit
                  </button>
                {/if}

                {#if canDelete(comment.author?.id)}
                  <button
                    onclick={() => handleDelete(comment.id)}
                    class="btn btn-ghost btn-xs text-base-content/60 hover:text-error"
                  >
                    Delete
                  </button>
                {/if}

                {#if current_user_id}
                  <button
                    onclick={() => handleReport(comment.id)}
                    class="btn btn-ghost btn-xs text-base-content/60 hover:text-base-content"
                  >
                    Report
                  </button>
                {/if}

                {#if current_user_id && depth < MAX_DEPTH}
                  <button
                    onclick={() => startReply(comment.id)}
                    class="btn btn-ghost btn-xs gap-1 text-primary hover:text-primary-focus"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h10a8 8 0 018 8v2M3 10l6 6m-6-6l6-6"/>
                    </svg>
                    Reply
                  </button>
                {/if}
              </div>
            </div>
          </div>

          <!-- Border below entire comment -->
          <div class="border-b border-base-300"></div>

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

<ReplyComposer
  isOpen={isComposerOpen}
  bind:replyText={replyText}
  placeholder="Write your reply... (Markdown supported)"
  onSubmit={submitReply}
  onDiscard={cancelReply}
/>
