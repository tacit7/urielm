<script>
  import { onMount } from 'svelte'
  import UMIcon from './UMIcon.svelte'

  let {
    isOpen = false,
    replyText = $bindable(""),
    placeholder = "Write your reply...",
    submitLabel = "Reply",
    draftKey = null,
    onSubmit = null,
    onDiscard = null
  } = $props()

  let textareaRef = $state(null)
  let isMobile = $state(false)
  let composerHeight = $state(260)
  let isFullscreen = $state(false)
  let isDragging = $state(false)
  let draftTimer = null
  let draftHydrated = $state(false)

  $effect(() => {
    if (isOpen && textareaRef) {
      textareaRef.focus()
    }
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

  function handleSubmit() {
    if (onSubmit && replyText.trim()) {
      onSubmit(replyText)
      clearDraft()
    }
  }

  function handleDiscard() {
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

  onMount(() => {
    if (!draftKey || typeof window === "undefined") {
      draftHydrated = true
      return
    }

    try {
      const draft = localStorage.getItem(draftKey)
      if (draft && !replyText.trim()) {
        replyText = draft
      }
    } catch (_) {}

    draftHydrated = true
  })

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

      <div class="min-h-0 flex-1">
        <textarea
          bind:this={textareaRef}
          bind:value={replyText}
          {placeholder}
          class="textarea min-h-full w-full resize-none rounded-xl border border-base-300/70 bg-base-100/80 px-3 py-2.5 text-sm leading-7 text-base-content placeholder:text-base-content/35 focus:border-secondary focus:outline-none"
          onkeydown={(e) => {
            if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
              handleSubmit()
            }
          }}
        ></textarea>
      </div>

      <div class="flex items-center justify-between gap-3 border-t border-base-300/60 pt-2">
        <div class="min-w-0 truncate text-xs text-base-content/45">
          <span class="hidden sm:inline">Press </span><kbd class="kbd kbd-sm">Cmd</kbd>+<kbd class="kbd kbd-sm">Enter</kbd>
        </div>
        <div class="flex shrink-0 gap-2">
          <button type="button" onclick={handleDiscard} class="btn btn-ghost btn-sm h-9 min-h-9 rounded-full px-3">
            Discard
          </button>
          <button
            type="button"
            onclick={handleSubmit}
            disabled={!replyText.trim()}
            class="btn btn-primary btn-sm h-9 min-h-9 rounded-full px-4"
          >
            {submitLabel}
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
