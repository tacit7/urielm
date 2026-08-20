<script>
  import VoteButtons from "./VoteButtons.svelte"
  import PostActions from "./PostActions.svelte"
  import CommentTree from "./CommentTree.svelte"
  import ReplyComposer from "./ReplyComposer.svelte"
  import MarkdownRenderer from "./MarkdownRenderer.svelte"
  import UMIcon from "./UMIcon.svelte"

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

<div class="space-y-3" data-comment-depth={depth}>
  {#if comments && comments.length > 0}
    {#each comments as comment (comment.id)}
      <article
        id="comment-{comment.id}"
        class="rounded-2xl border border-base-300/50 bg-base-200/30 p-4 transition-colors duration-150 hover:bg-base-200/45 sm:p-5"
      >
        <div>
          <div class="flex items-start justify-between gap-4">
            <div class="flex-1">
              <div class="mb-3 flex items-center gap-3">
                {#if comment.author?.avatar_url}
                  <img
                    src={comment.author.avatar_url}
                    alt={comment.author?.username || "User"}
                    class="size-9 rounded-full object-cover"
                  />
                {:else}
                  <div class="flex size-9 items-center justify-center rounded-full bg-secondary text-xs font-black text-secondary-content">
                    {(comment.author?.username || "U")[0].toUpperCase()}
                  </div>
                {/if}
                <div>
                  <p class="text-sm font-semibold text-base-content">
                    {comment.author?.username || "Unknown"}
                  </p>
                  <span class="text-xs text-base-content/40">
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
                <div class="mb-4 text-sm leading-7 text-base-content/80 sm:text-base">
                  <MarkdownRenderer content={comment.body} enableEmbeds={false} />
                  {#if comment.edited_at}
                    <span class="text-xs text-base-content/50 ml-2">(edited)</span>
                  {/if}
                </div>
              {/if}

              <div class="flex items-center gap-3">
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
            <div class="flex items-center justify-end">
              <!-- Actions on right -->
              <div class="flex items-center gap-1">
                {#if canEdit(comment.author?.id) && editingId !== comment.id}
                  <button
                    onclick={() => startEdit(comment.id, comment.body)}
                    class="btn btn-ghost btn-xs text-base-content/45 hover:text-base-content"
                  >
                    Edit
                  </button>
                {/if}

                {#if canDelete(comment.author?.id)}
                  <button
                    onclick={() => handleDelete(comment.id)}
                    class="btn btn-ghost btn-xs text-base-content/45 hover:text-error"
                  >
                    Delete
                  </button>
                {/if}

                {#if current_user_id}
                  <button
                    onclick={() => handleReport(comment.id)}
                    class="btn btn-ghost btn-xs text-base-content/45 hover:text-base-content"
                  >
                    Report
                  </button>
                {/if}

                {#if current_user_id && depth < MAX_DEPTH}
                  <button
                    onclick={() => startReply(comment.id)}
                    class="btn btn-ghost btn-xs gap-1 text-secondary hover:bg-secondary/10 hover:text-secondary"
                  >
                    <UMIcon name="reply" className="w-4 h-4" />
                    Reply
                  </button>
                {/if}
              </div>
            </div>
          </div>

          <!-- Nested replies -->
          {#if comment.replies && comment.replies.length > 0 && depth < MAX_DEPTH}
            <div class="mt-3 ml-4 rounded-2xl bg-base-200/20 p-2 sm:ml-8">
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
      </article>
    {/each}
  {:else}
    <div class="rounded-2xl border border-dashed border-base-300/70 px-5 py-12 text-center">
      <p class="font-semibold text-base-content/65">No replies yet</p>
      <p class="mt-1 text-sm text-base-content/40">Be the first to add something useful.</p>
    </div>
  {/if}
</div>

<ReplyComposer
  isOpen={isComposerOpen}
  bind:replyText={replyText}
  placeholder="Write your reply... (Markdown supported)"
  onSubmit={submitReply}
  onDiscard={cancelReply}
/>
