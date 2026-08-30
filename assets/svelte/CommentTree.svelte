<script>
  import VoteButtons from "./VoteButtons.svelte"
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
    reply_draft_key = null,
    reply_upload_url = null,
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
  let nestedSpacing = $derived(depth >= 2 ? "mt-2.5 border-l border-base-300/70 pl-1.5 sm:pl-2.5" : "mt-2.5 border-l border-base-300/70 pl-2 sm:pl-3")
  let avatarClass = $derived(depth >= 2 ? "size-6" : "size-7")
  let avatarTextClass = $derived(depth >= 2 ? "text-[0.6rem]" : "text-[0.65rem]")

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
    return String(current_user_id) === String(authorId) || current_user_is_admin
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
    if (!text.trim() || !live) return false

    return new Promise((resolve) => {
      live.pushEvent(
        "create_composer_reply",
        {
          body: text,
          parent_id: composerParentId
        },
        (response) => {
          if (response?.ok) {
            isComposerOpen = false
            composerParentId = null
            replyText = ""
            resolve(true)
          } else {
            resolve(false)
          }
        }
      )
    })
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
    return String(current_user_id) === String(authorId) || current_user_is_admin
  }

  function canMarkSolved() {
    if (!current_user_id) return false
    return String(current_user_id) === String(thread_author_id) || current_user_is_admin
  }

  function handleMarkSolved(commentId) {
    if (live) {
      live.pushEvent("mark_solved", { comment_id: commentId })
    }
  }
</script>

<div class={depth === 0 ? "divide-y divide-base-300/45" : "space-y-1.5"} data-comment-depth={depth}>
  {#if comments && comments.length > 0}
    {#each comments as comment (comment.id)}
      <article
        id="comment-{comment.id}"
        class={[
          "group py-3 transition-colors duration-150",
          depth === 0 ? "first:pt-0 last:pb-0" : "rounded-lg px-2.5 py-2.5 hover:bg-base-200/35",
          solved_comment_id === comment.id && "rounded-lg bg-success/5 ring-1 ring-success/20"
        ]}
      >
        <div class="flex items-start gap-2">
          <div class="shrink-0">
            {#if comment.author?.avatar_url}
              <img
                src={comment.author.avatar_url}
                alt={comment.author?.username || "User"}
                class={`${avatarClass} rounded-full object-cover ring-1 ring-base-300/70`}
              />
            {:else}
              <div class={`flex ${avatarClass} items-center justify-center rounded-full bg-secondary ${avatarTextClass} font-black text-secondary-content ring-1 ring-secondary/20`}>
                {(comment.author?.username || "U")[0].toUpperCase()}
              </div>
            {/if}
          </div>

          <div class="min-w-0 flex-1">
            <header class="flex flex-wrap items-center gap-x-2 gap-y-1">
              <a href="#comment-{comment.id}" class="text-sm font-semibold text-base-content hover:text-primary">
                {comment.author?.username || "Unknown"}
              </a>
              {#if solved_comment_id === comment.id}
                <span class="badge badge-success badge-xs h-4 min-h-4 gap-1 px-1.5 text-[0.625rem]">
                  <UMIcon name="hero-check" className="size-3" />
                  solution
                </span>
              {/if}
              <span class="font-mono text-[0.7rem] text-base-content/35">
                {formatDate(comment.inserted_at)}
              </span>
              {#if comment.edited_at}
                <span class="text-xs text-base-content/35">edited</span>
              {/if}
            </header>

            {#if editingId === comment.id}
              <div class="mt-3">
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
              <div class="prose prose-sm mt-1.5 max-w-none leading-6 text-base-content/80">
                <MarkdownRenderer content={comment.body} enableEmbeds={false} />
              </div>
            {/if}

            <div class="mt-2 flex flex-wrap items-center gap-x-1.5 gap-y-1">
              <VoteButtons
                target_type="comment"
                target_id={comment.id}
                score={comment.score || 0}
                user_vote={comment.user_vote}
                {live}
              />

              {#if current_user_id && depth < MAX_DEPTH}
                <button
                  onclick={() => startReply(comment.id)}
                  class="btn btn-ghost btn-xs h-7 min-h-7 gap-1 rounded-md px-2 text-base-content/50 hover:bg-secondary/10 hover:text-secondary"
                >
                  <UMIcon name="reply" className="size-3.5" />
                  Reply
                </button>
              {/if}

              {#if canMarkSolved() && solved_comment_id !== comment.id}
                <button
                  onclick={() => handleMarkSolved(comment.id)}
                  class="btn btn-ghost btn-xs h-7 min-h-7 gap-1 rounded-md px-2 text-base-content/50 hover:bg-success/10 hover:text-success"
                >
                  <UMIcon name="hero-check-circle" className="size-3.5" />
                  Solution
                </button>
              {/if}

              <div class="ml-auto flex items-center gap-1 opacity-100 transition-opacity sm:opacity-0 sm:group-hover:opacity-100 sm:group-focus-within:opacity-100">
                {#if canEdit(comment.author?.id) && editingId !== comment.id}
                  <button
                    onclick={() => startEdit(comment.id, comment.body)}
                    class="btn btn-ghost btn-xs h-7 min-h-7 rounded-md px-2 text-base-content/45 hover:text-base-content"
                  >
                    Edit
                  </button>
                {/if}

                {#if canDelete(comment.author?.id)}
                  <button
                    onclick={() => handleDelete(comment.id)}
                    class="btn btn-ghost btn-xs h-7 min-h-7 rounded-md px-2 text-base-content/45 hover:text-error"
                  >
                    Delete
                  </button>
                {/if}

                {#if current_user_id}
                  <button
                    onclick={() => handleReport(comment.id)}
                    class="btn btn-ghost btn-xs h-7 min-h-7 rounded-md px-2 text-base-content/45 hover:text-base-content"
                  >
                    Report
                  </button>
                {/if}
              </div>
            </div>

            {#if comment.replies && comment.replies.length > 0 && depth < MAX_DEPTH}
              <div class={nestedSpacing}>
                <CommentTree
                  comments={comment.replies}
                  current_user_id={current_user_id}
                  current_user_is_admin={current_user_is_admin}
                  thread_author_id={thread_author_id}
                  solved_comment_id={solved_comment_id}
                  reply_draft_key={reply_draft_key}
                  reply_upload_url={reply_upload_url}
                  {live}
                  depth={depth + 1}
                />
              </div>
            {/if}
          </div>
        </div>
      </article>
    {/each}
  {:else}
    <div class="rounded-xl border border-dashed border-base-300/70 px-4 py-8 text-center">
      <p class="font-semibold text-base-content/65">No replies yet</p>
      <p class="mt-1 text-sm text-base-content/40">Be the first to add something useful.</p>
    </div>
  {/if}
</div>

<ReplyComposer
  isOpen={isComposerOpen}
  bind:replyText={replyText}
  placeholder="Write your reply... (Markdown supported)"
  draftKey={reply_draft_key}
  uploadUrl={reply_upload_url}
  onSubmit={submitReply}
  onDiscard={cancelReply}
/>
