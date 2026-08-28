<script>
  import MarkdownRenderer from "./MarkdownRenderer.svelte"
  import { appendUploadsToReply } from "./replyComposerUpload.js"
  import UMIcon from './UMIcon.svelte'

  let {
    isOpen = false,
    replyText = $bindable(""),
    placeholder = "Write your reply...",
    submitLabel = "Reply",
    draftKey = null,
    uploadUrl = null,
    onSubmit = null,
    onDiscard = null
  } = $props()

  let textareaRef = $state(null)
  let uploadInputRef = $state(null)
  let isMobile = $state(false)
  let composerHeight = $state(260)
  let isFullscreen = $state(false)
  let isDragging = $state(false)
  let isSubmitting = $state(false)
  let selectedFiles = $state([])
  let uploadError = $state("")
  let draftTimer = null
  let draftHydrated = $state(false)

  $effect(() => {
    if (isOpen && textareaRef) {
      textareaRef.focus()
    }
  })

  $effect(() => {
    if (!isOpen) {
      draftHydrated = false
      return
    }

    if (draftHydrated) return

    if (draftKey && typeof window !== "undefined") {
      try {
        const draft = localStorage.getItem(draftKey)
        if (draft && !replyText.trim()) replyText = draft
      } catch (_) {}
    }

    draftHydrated = true
  })

  $effect(() => {
    if (!draftHydrated || !draftKey || typeof window === "undefined") {
      return
    }

    if (!replyText.trim()) {
      try {
        localStorage.removeItem(draftKey)
      } catch (_) {}

      return
    }

    clearTimeout(draftTimer)
    draftTimer = setTimeout(() => {
      try {
        localStorage.setItem(draftKey, replyText)
      } catch (_) {}
    }, 200)

    return () => clearTimeout(draftTimer)
  })

  async function handleSubmit() {
    if (!onSubmit || !replyText.trim() || isSubmitting) return

    isSubmitting = true
    uploadError = ""

    try {
      const uploads = await uploadFiles()
      const submissionText = appendUploadsToReply(replyText, uploads)

      if (uploads.length > 0) {
        replyText = submissionText
        selectedFiles = []
        resetUploadInput()
      }

      const accepted = await onSubmit(submissionText)

      if (accepted !== false) {
        clearDraft()
      }
    } catch (error) {
      uploadError = error instanceof Error ? error.message : "Upload failed"
    } finally {
      isSubmitting = false
    }
  }

  async function uploadFiles() {
    if (selectedFiles.length === 0) return []
    if (!uploadUrl) throw new Error("Uploads are not available for this reply")

    const csrfToken = document
      .querySelector('meta[name="csrf-token"]')
      ?.getAttribute("content")
    const uploads = []

    for (const file of selectedFiles) {
      const formData = new FormData()
      formData.append("file", file)

      const response = await fetch(uploadUrl, {
        method: "POST",
        body: formData,
        headers: csrfToken ? { "x-csrf-token": csrfToken } : {}
      })
      const payload = await response.json().catch(() => ({}))

      if (!response.ok) {
        throw new Error(payload.error || `Could not upload ${file.name}`)
      }

      uploads.push(payload)
    }

    return uploads
  }

  function selectFiles(event) {
    selectedFiles = Array.from(event.currentTarget.files || [])
    uploadError = ""
  }

  function resetUploadInput() {
    if (uploadInputRef) uploadInputRef.value = ""
  }

  function handleDiscard() {
    selectedFiles = []
    uploadError = ""
    resetUploadInput()
    clearDraft()

    if (onDiscard) {
      onDiscard()
    }
  }

  function checkMobile() {
    isMobile = window.innerWidth < 768
  }

  function toggleFullscreen() {
    isFullscreen = !isFullscreen

    if (typeof window !== 'undefined') {
      window.dispatchEvent(new CustomEvent('composer-fullscreen', {
        detail: { isFullscreen: isFullscreen }
      }))
    }
  }

  function startDrag(e) {
    isDragging = true
    const startY = e.clientY
    const startHeight = composerHeight

    function onMove(e) {
      const delta = startY - e.clientY
      composerHeight = Math.max(180, Math.min(window.innerHeight - 100, startHeight + delta))
    }

    function onUp() {
      isDragging = false
      document.removeEventListener('mousemove', onMove)
      document.removeEventListener('mouseup', onUp)
    }

    document.addEventListener('mousemove', onMove)
    document.addEventListener('mouseup', onUp)
  }

  function clearDraft() {
    if (!draftKey || typeof window === "undefined") {
      return
    }

    clearTimeout(draftTimer)

    try {
      localStorage.removeItem(draftKey)
    } catch (_) {}
  }

  $effect(() => {
    if (typeof window !== 'undefined') {
      checkMobile()
      window.addEventListener('resize', checkMobile)
      return () => window.removeEventListener('resize', checkMobile)
    }
  })
</script>

<div
  class:open={isOpen}
  class:fullscreen={isFullscreen}
  class="reply-composer fixed bottom-[calc(3.5rem+env(safe-area-inset-bottom))] left-0 right-0 z-[45] mx-auto flex w-full max-w-3xl flex-col transition-all duration-200 md:bottom-0"
  class:hidden={!isOpen}
  style:height={isFullscreen ? '100vh' : isOpen ? `${composerHeight}px` : '0'}
>
  {#if isOpen && !isMobile}
    <button
      type="button"
      class="grippie w-full cursor-row-resize rounded-t-2xl bg-primary"
      onmousedown={startDrag}
      aria-label="Resize composer"
    ></button>
  {/if}

  <div class="h-full rounded-none border border-base-300/70 bg-base-200 shadow-2xl md:rounded-t-2xl">
    <div class="flex h-full flex-col gap-2 p-3 sm:p-4">
      <div class="flex items-center justify-between gap-3 border-b border-base-300/60 pb-2">
        <div class="min-w-0">
          <p class="text-sm font-bold text-base-content">Reply</p>
          <p class="truncate text-xs text-base-content/40">Markdown supported. Drafts stay on this device.</p>
        </div>
        <div class="flex shrink-0 gap-1">
          {#if !isMobile}
            <button
              type="button"
              onclick={toggleFullscreen}
              class="btn btn-ghost btn-xs btn-circle tooltip tooltip-left text-base-content/55 hover:text-base-content"
              data-tip={isFullscreen ? 'Exit fullscreen' : 'Fullscreen'}
              aria-label={isFullscreen ? 'Exit fullscreen' : 'Fullscreen'}
            >
              {#if isFullscreen}
                <UMIcon name="hero-chevron-down" className="size-4" />
              {:else}
                <UMIcon name="hero-arrows-pointing-out" className="size-4" />
              {/if}
            </button>
          {/if}
          <button
            type="button"
            onclick={handleDiscard}
            class="btn btn-ghost btn-xs btn-circle text-base-content/55 hover:text-base-content"
            aria-label="Close"
          >
            <UMIcon name="hero-x-mark" className="size-4" />
          </button>
        </div>
      </div>

      <div class="grid min-h-0 flex-1 grid-cols-1 overflow-hidden rounded-xl border border-base-300/70 bg-base-100/80 md:grid-cols-2">
        <div class="form-control min-h-0 border-b border-base-300/70 md:border-b-0 md:border-r">
          <textarea
            bind:this={textareaRef}
            bind:value={replyText}
            {placeholder}
            aria-label="Write reply"
            class="textarea h-full w-full resize-none rounded-none border-0 bg-transparent px-3 py-2.5 text-sm leading-7 text-base-content placeholder:text-base-content/35 focus:outline-none"
            onkeydown={(e) => {
              if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
                handleSubmit()
              }
            }}
          ></textarea>
        </div>
        <section
          aria-label="Preview reply"
          class="min-h-0 overflow-y-auto bg-base-200/35 p-3 sm:p-4"
        >
          <p class="mb-3 text-xs font-bold uppercase tracking-[0.14em] text-secondary">
            Preview
          </p>
          {#if replyText.trim()}
            <MarkdownRenderer content={replyText} enableEmbeds={false} />
          {:else}
            <p class="text-sm text-base-content/40">Your formatted reply will appear here.</p>
          {/if}
        </section>
      </div>

      <div class="flex flex-col gap-2 border-t border-base-300/60 pt-2 sm:flex-row sm:items-center sm:justify-between">
        <div class="min-w-0 truncate text-xs text-base-content/45">
          {#if uploadError}
            <p role="alert" class="text-xs text-error">{uploadError}</p>
          {:else if selectedFiles.length > 0}
            <p class="truncate text-xs text-success">
              {selectedFiles.length === 1 ? selectedFiles[0].name : `${selectedFiles.length} files ready`}
            </p>
          {:else}
            <p>
              <span class="hidden sm:inline">Press </span><kbd class="kbd kbd-sm">Cmd</kbd>+<kbd class="kbd kbd-sm">Enter</kbd>
            </p>
          {/if}
        </div>
        <div class="flex shrink-0 items-center justify-end gap-2">
          {#if uploadUrl}
            <label class="btn btn-ghost btn-sm h-9 min-h-9 cursor-pointer rounded-full px-3" aria-label="Attach files">
              <UMIcon name="hero-paper-clip" className="size-4" />
              <span class="hidden sm:inline">Attach</span>
              <input
                bind:this={uploadInputRef}
                type="file"
                multiple
                accept=".jpg,.jpeg,.png,.gif,.webp,.pdf,.doc,.docx,.txt"
                class="sr-only"
                onchange={selectFiles}
              />
            </label>
          {/if}
          <button type="button" onclick={handleDiscard} class="btn btn-ghost btn-sm h-9 min-h-9 rounded-full px-3">
            Discard
          </button>
          <button
            type="button"
            onclick={handleSubmit}
            disabled={!replyText.trim() || isSubmitting}
            class="btn btn-primary btn-sm h-9 min-h-9 rounded-full px-4"
          >
            {isSubmitting ? "Posting…" : submitLabel}
          </button>
        </div>
      </div>
    </div>
  </div>
</div>

<style>
  .grippie::before {
    content: "";
    display: block;
    width: 1.5em;
    margin: auto;
    padding: 0.25em 0;
    border-top: 3px double oklch(var(--pc));
  }

  @media (max-width: 768px) {
    .reply-composer.open:not(.fullscreen) {
      height: min(72dvh, 34rem) !important;
    }

    .reply-composer.fullscreen {
      bottom: 0;
    }

    .grippie {
      display: none;
    }
  }
</style>
