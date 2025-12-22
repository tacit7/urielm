<script>
  let {
    isOpen = false,
    replyText = $bindable(""),
    placeholder = "Write your reply...",
    submitLabel = "Reply",
    onSubmit = null,
    onDiscard = null
  } = $props()

  let textareaRef = $state(null)
  let isMobile = $state(false)
  let composerHeight = $state(300)
  let isFullscreen = $state(false)
  let isDragging = $state(false)

  $effect(() => {
    if (isOpen && textareaRef) {
      textareaRef.focus()
    }
  })

  function handleSubmit() {
    if (onSubmit && replyText.trim()) {
      onSubmit(replyText)
    }
  }

  function handleDiscard() {
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
      composerHeight = Math.max(200, Math.min(window.innerHeight - 100, startHeight + delta))
    }

    function onUp() {
      isDragging = false
      document.removeEventListener('mousemove', onMove)
      document.removeEventListener('mouseup', onUp)
    }

    document.addEventListener('mousemove', onMove)
    document.addEventListener('mouseup', onUp)
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
  class="fixed bottom-0 left-0 right-0 mx-auto w-full max-w-3xl z-40 transition-all duration-200 flex flex-col"
  class:hidden={!isOpen}
  style:height={isFullscreen ? '100vh' : isOpen ? `${composerHeight}px` : '0'}
>
  {#if isOpen && !isMobile}
    <button
      type="button"
      class="grippie cursor-row-resize bg-primary rounded-t-2xl w-full"
      onmousedown={startDrag}
      aria-label="Resize composer"
    ></button>
  {/if}

  <div class="card bg-base-200 shadow-2xl h-full rounded-none md:rounded-t-2xl">
    <div class="card-body p-4 flex flex-col h-full gap-2">
      <!-- Header -->
      <div class="flex items-center justify-between">
        <span class="text-sm text-base-content/70">Replying...</span>
        <div class="flex gap-2">
          {#if !isMobile}
            <button
              type="button"
              onclick={toggleFullscreen}
              class="btn btn-ghost btn-xs btn-circle tooltip tooltip-left"
              data-tip={isFullscreen ? 'Exit fullscreen' : 'Fullscreen'}
            >
              {#if isFullscreen}
                <span class="hero hero-chevron-down"></span>
              {:else}
                <span class="hero hero-arrows-pointing-out"></span>
              {/if}
            </button>
          {/if}
          <button
            type="button"
            onclick={handleDiscard}
            class="btn btn-ghost btn-xs btn-circle"
            aria-label="Close"
          >
            <span class="hero hero-x-mark"></span>
          </button>
        </div>
      </div>

      <!-- Editor -->
      <div class="form-control flex-1 min-h-0">
        <textarea
          bind:this={textareaRef}
          bind:value={replyText}
          {placeholder}
          class="textarea textarea-ghost w-full h-full resize-none text-base leading-relaxed"
          onkeydown={(e) => {
            if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
              handleSubmit()
            }
          }}
        ></textarea>
      </div>

      <!-- Footer -->
      <div class="flex items-center justify-between pt-2 border-t border-base-300">
        <div class="text-xs text-base-content/60">
          Press <kbd class="kbd kbd-sm">Cmd</kbd>+<kbd class="kbd kbd-sm">Enter</kbd> to submit
        </div>
        <div class="flex gap-2">
          <button type="button" onclick={handleDiscard} class="btn btn-ghost btn-sm">
            Discard
          </button>
          <button type="button" onclick={handleSubmit} disabled={!replyText.trim()} class="btn btn-primary btn-sm">
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
    .fixed.bottom-0.open:not(.fullscreen) {
      height: 100vh !important;
    }

    .grippie {
      display: none;
    }
  }
</style>
