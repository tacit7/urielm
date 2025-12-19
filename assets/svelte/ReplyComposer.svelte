<script>
  import TiptapEditor from './TiptapEditor.svelte'
  import { Bold, Italic, Heading2, Link, Quote, Code, FileCode, List, ListOrdered } from 'lucide-svelte'

  export let isOpen = false
  export let replyText = ""
  export let placeholder = "Write your reply..."
  export let onSubmit = null
  export let onDiscard = null

  let textareaRef = null
  let tiptapRef = null
  let isMobile = false
  let composerHeight = 400
  let isFullscreen = false
  let isDragging = false
  let editorMode = 'markdown' // 'markdown' or 'rich'
  let activeFormats = {
    isBold: false,
    isItalic: false,
    isHeading: false,
    isCode: false,
    isCodeBlock: false,
    isBulletList: false,
    isOrderedList: false,
    isBlockquote: false
  }

  $: if (isOpen) {
    if (editorMode === 'markdown' && textareaRef) {
      textareaRef.focus()
    } else if (editorMode === 'rich' && tiptapRef) {
      tiptapRef.focus()
    }
  }

  function handleSubmit() {
    if (onSubmit) {
      // Get content based on mode
      const content = editorMode === 'rich' ? tiptapRef?.getText() || '' : replyText
      if (content.trim()) {
        onSubmit(content)
      }
    }
  }

  function toggleEditorMode() {
    editorMode = editorMode === 'markdown' ? 'rich' : 'markdown'
  }

  function handleTiptapUpdate(html) {
    // Update replyText with HTML content
    // For now, just store as text
    replyText = tiptapRef?.getText() || ''
  }

  function handleSelectionUpdate(formats) {
    activeFormats = formats
  }

  function handleDiscard() {
    if (onDiscard) {
      onDiscard()
    }
  }

  function insertMarkdown(before, after = '') {
    if (!textareaRef) return

    const start = textareaRef.selectionStart
    const end = textareaRef.selectionEnd
    const selectedText = replyText.substring(start, end)
    const replacement = before + selectedText + after

    replyText = replyText.substring(0, start) + replacement + replyText.substring(end)

    setTimeout(() => {
      const newPos = start + before.length + selectedText.length
      textareaRef.selectionStart = newPos
      textareaRef.selectionEnd = newPos
      textareaRef.focus()
    }, 0)
  }

  function checkMobile() {
    isMobile = window.innerWidth < 768
  }

  function toggleFullscreen() {
    isFullscreen = !isFullscreen

    // Toggle navbar visibility
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
      composerHeight = Math.max(255, Math.min(window.innerHeight - 100, startHeight + delta))
    }

    function onUp() {
      isDragging = false
      document.removeEventListener('mousemove', onMove)
      document.removeEventListener('mouseup', onUp)
    }

    document.addEventListener('mousemove', onMove)
    document.addEventListener('mouseup', onUp)
  }

  if (typeof window !== 'undefined') {
    checkMobile()
    window.addEventListener('resize', checkMobile)
  }
</script>

<div
  class:open={isOpen}
  class:fullscreen={isFullscreen}
  class="fixed bottom-0 left-0 right-0 mx-auto w-full max-w-3xl z-40 transition-all duration-200 flex flex-col"
  class:hidden={!isOpen}
  style:height={isFullscreen ? '100vh' : isOpen ? `${composerHeight}px` : '0'}
>
  {#if isOpen && !isMobile}
    <div
      class="grippie cursor-row-resize bg-primary rounded-t-2xl"
      on:mousedown={startDrag}
      role="separator"
      aria-label="Resize composer"
    ></div>
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
              on:click={toggleFullscreen}
              class="btn btn-ghost btn-xs btn-circle tooltip tooltip-left"
              data-tip={isFullscreen ? 'Exit fullscreen' : 'Fullscreen'}
            >
              {#if isFullscreen}
                ⌄
              {:else}
                ⤢
              {/if}
            </button>
          {/if}
          <button
            type="button"
            on:click={handleDiscard}
            class="btn btn-ghost btn-xs btn-circle"
            aria-label="Close"
          >
            ✕
          </button>
        </div>
      </div>

      <!-- Mode Toggle -->
      <div class="flex gap-2 mb-2">
        <button
          type="button"
          class="btn btn-xs"
          class:btn-primary={editorMode === 'markdown'}
          class:btn-ghost={editorMode !== 'markdown'}
          on:click={() => editorMode = 'markdown'}
        >
          Markdown
        </button>
        <button
          type="button"
          class="btn btn-xs"
          class:btn-primary={editorMode === 'rich'}
          class:btn-ghost={editorMode !== 'rich'}
          on:click={() => editorMode = 'rich'}
        >
          Rich Text
        </button>
      </div>

      <!-- Toolbar -->
      <div class="flex gap-1 p-2 border-b border-base-300 flex-wrap">
      {#if editorMode === 'markdown'}
        <!-- Markdown toolbar -->
        <button type="button" on:click={() => insertMarkdown('**', '**')} class="btn btn-ghost btn-xs tooltip tooltip-top" data-tip="Bold">
          <Bold class="w-4 h-4" />
        </button>
        <button type="button" on:click={() => insertMarkdown('*', '*')} class="btn btn-ghost btn-xs tooltip tooltip-top" data-tip="Italic">
          <Italic class="w-4 h-4" />
        </button>
        <button type="button" on:click={() => insertMarkdown('## ', '')} class="btn btn-ghost btn-xs tooltip tooltip-top" data-tip="Heading">
          <Heading2 class="w-4 h-4" />
        </button>
        <div class="divider divider-horizontal mx-1 my-0"></div>
        <button type="button" on:click={() => insertMarkdown('[', '](url)')} class="btn btn-ghost btn-xs tooltip tooltip-top" data-tip="Link">
          <Link class="w-4 h-4" />
        </button>
        <button type="button" on:click={() => insertMarkdown('> ', '')} class="btn btn-ghost btn-xs tooltip tooltip-top" data-tip="Quote">
          <Quote class="w-4 h-4" />
        </button>
        <button type="button" on:click={() => insertMarkdown('`', '`')} class="btn btn-ghost btn-xs tooltip tooltip-top" data-tip="Inline Code">
          <Code class="w-4 h-4" />
        </button>
        <button type="button" on:click={() => insertMarkdown('```\n', '\n```')} class="btn btn-ghost btn-xs tooltip tooltip-top" data-tip="Code Block">
          <FileCode class="w-4 h-4" />
        </button>
        <div class="divider divider-horizontal mx-1 my-0"></div>
        <button type="button" on:click={() => insertMarkdown('- ', '')} class="btn btn-ghost btn-xs tooltip tooltip-top" data-tip="Bullet List">
          <List class="w-4 h-4" />
        </button>
        <button type="button" on:click={() => insertMarkdown('1. ', '')} class="btn btn-ghost btn-xs tooltip tooltip-top" data-tip="Numbered List">
          <ListOrdered class="w-4 h-4" />
        </button>
      {:else}
        <!-- Rich text toolbar -->
        <button
          type="button"
          on:click={() => tiptapRef?.toggleBold()}
          class="btn btn-xs tooltip tooltip-top"
          class:btn-active={activeFormats.isBold}
          class:btn-ghost={!activeFormats.isBold}
          data-tip="Bold"
        >
          <Bold class="w-4 h-4" />
        </button>
        <button
          type="button"
          on:click={() => tiptapRef?.toggleItalic()}
          class="btn btn-xs tooltip tooltip-top"
          class:btn-active={activeFormats.isItalic}
          class:btn-ghost={!activeFormats.isItalic}
          data-tip="Italic"
        >
          <Italic class="w-4 h-4" />
        </button>
        <button
          type="button"
          on:click={() => tiptapRef?.toggleHeading(2)}
          class="btn btn-xs tooltip tooltip-top"
          class:btn-active={activeFormats.isHeading}
          class:btn-ghost={!activeFormats.isHeading}
          data-tip="Heading"
        >
          <Heading2 class="w-4 h-4" />
        </button>
        <div class="divider divider-horizontal mx-1 my-0"></div>
        <button type="button" on:click={() => tiptapRef?.setLink()} class="btn btn-ghost btn-xs tooltip tooltip-top" data-tip="Link">
          <Link class="w-4 h-4" />
        </button>
        <button
          type="button"
          on:click={() => tiptapRef?.toggleBlockquote()}
          class="btn btn-xs tooltip tooltip-top"
          class:btn-active={activeFormats.isBlockquote}
          class:btn-ghost={!activeFormats.isBlockquote}
          data-tip="Quote"
        >
          <Quote class="w-4 h-4" />
        </button>
        <button
          type="button"
          on:click={() => tiptapRef?.toggleCode()}
          class="btn btn-xs tooltip tooltip-top"
          class:btn-active={activeFormats.isCode}
          class:btn-ghost={!activeFormats.isCode}
          data-tip="Inline Code"
        >
          <Code class="w-4 h-4" />
        </button>
        <button
          type="button"
          on:click={() => tiptapRef?.toggleCodeBlock()}
          class="btn btn-xs tooltip tooltip-top"
          class:btn-active={activeFormats.isCodeBlock}
          class:btn-ghost={!activeFormats.isCodeBlock}
          data-tip="Code Block"
        >
          <FileCode class="w-4 h-4" />
        </button>
        <div class="divider divider-horizontal mx-1 my-0"></div>
        <button
          type="button"
          on:click={() => tiptapRef?.toggleBulletList()}
          class="btn btn-xs tooltip tooltip-top"
          class:btn-active={activeFormats.isBulletList}
          class:btn-ghost={!activeFormats.isBulletList}
          data-tip="Bullet List"
        >
          <List class="w-4 h-4" />
        </button>
        <button
          type="button"
          on:click={() => tiptapRef?.toggleOrderedList()}
          class="btn btn-xs tooltip tooltip-top"
          class:btn-active={activeFormats.isOrderedList}
          class:btn-ghost={!activeFormats.isOrderedList}
          data-tip="Numbered List"
        >
          <ListOrdered class="w-4 h-4" />
        </button>
      {/if}
      </div>

      <!-- Editor -->
      <div class="form-control flex-1 min-h-0">
        {#if editorMode === 'markdown'}
          <textarea
            bind:this={textareaRef}
            bind:value={replyText}
            {placeholder}
            class="textarea textarea-ghost w-full h-full resize-none text-base leading-relaxed"
            on:keydown={(e) => {
              if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
                handleSubmit()
              }
            }}
          ></textarea>
        {:else}
          <TiptapEditor
            bind:this={tiptapRef}
            content={replyText}
            {placeholder}
            onUpdate={handleTiptapUpdate}
            onSelectionUpdate={handleSelectionUpdate}
          />
        {/if}
      </div>

      <!-- Footer -->
      <div class="flex items-center justify-between pt-2 border-t border-base-300">
        <div class="text-xs text-base-content/60">
          Press <kbd class="kbd kbd-sm">Cmd</kbd>+<kbd class="kbd kbd-sm">Enter</kbd> to submit
        </div>
        <div class="flex gap-2">
          <button type="button" on:click={handleDiscard} class="btn btn-ghost btn-sm">
            Discard
          </button>
          <button type="button" on:click={handleSubmit} disabled={!replyText.trim()} class="btn btn-primary btn-sm">
            Reply
          </button>
        </div>
      </div>
    </div>
  </div>
</div>

<style>
  /* Custom grippie styling (no DaisyUI equivalent) */
  .grippie::before {
    content: "";
    display: block;
    width: 1.5em;
    margin: auto;
    padding: 0.25em 0;
    border-top: 3px double oklch(var(--pc));
  }

  /* Mobile fullscreen override */
  @media (max-width: 768px) {
    .fixed.bottom-0.open:not(.fullscreen) {
      height: 100vh !important;
    }

    .grippie {
      display: none;
    }
  }
</style>
