<script>
  import { Editor } from '@tiptap/core'
  import StarterKit from '@tiptap/starter-kit'
  import TiptapLink from '@tiptap/extension-link'
  import { onMount, onDestroy } from 'svelte'

  let {
    content = '',
    placeholder = 'Write something...',
    onUpdate = null,
    onSelectionUpdate = null
  } = $props()

  let editorElement
  let editor
  let showLinkPopover = $state(false)
  let linkUrl = $state('')
  let linkInputRef

  // Focus input when popover opens
  $effect(() => {
    if (showLinkPopover && linkInputRef) {
      setTimeout(() => linkInputRef?.focus(), 50)
    }
  })

  onMount(() => {
    editor = new Editor({
      element: editorElement,
      extensions: [
        StarterKit.configure({
          heading: {
            levels: [1, 2, 3]
          },
          codeBlock: {
            HTMLAttributes: {
              class: 'bg-base-300 p-4 rounded-lg text-sm'
            }
          },
          // Disable Link from StarterKit to avoid duplicate
          link: false
        }),
        TiptapLink.configure({
          openOnClick: false,
          HTMLAttributes: {
            class: 'link link-primary'
          }
        })
      ],
      content: content,
      editorProps: {
        attributes: {
          class: 'prose prose-sm max-w-none focus:outline-none min-h-full p-4 text-base-content'
        }
      },
      onUpdate: ({ editor }) => {
        const html = editor.getHTML()
        if (onUpdate) {
          onUpdate(html)
        }
      },
      onSelectionUpdate: ({ editor }) => {
        if (onSelectionUpdate) {
          onSelectionUpdate({
            isBold: editor.isActive('bold'),
            isItalic: editor.isActive('italic'),
            isHeading: editor.isActive('heading'),
            isCode: editor.isActive('code'),
            isCodeBlock: editor.isActive('codeBlock'),
            isBulletList: editor.isActive('bulletList'),
            isOrderedList: editor.isActive('orderedList'),
            isBlockquote: editor.isActive('blockquote')
          })
        }
      }
    })
  })

  onDestroy(() => {
    if (editor) {
      editor.destroy()
    }
  })

  export function getHTML() {
    return editor ? editor.getHTML() : ''
  }

  export function getText() {
    return editor ? editor.getText() : ''
  }

  export function setContent(newContent) {
    if (editor) {
      editor.commands.setContent(newContent)
    }
  }

  export function focus() {
    if (editor) {
      editor.commands.focus()
    }
  }

  // Toolbar actions
  export function toggleBold() {
    editor?.chain().focus().toggleBold().run()
  }

  export function toggleItalic() {
    editor?.chain().focus().toggleItalic().run()
  }

  export function toggleCode() {
    editor?.chain().focus().toggleCode().run()
  }

  export function toggleHeading(level) {
    editor?.chain().focus().toggleHeading({ level }).run()
  }

  export function toggleBulletList() {
    editor?.chain().focus().toggleBulletList().run()
  }

  export function toggleOrderedList() {
    editor?.chain().focus().toggleOrderedList().run()
  }

  export function toggleBlockquote() {
    editor?.chain().focus().toggleBlockquote().run()
  }

  export function toggleCodeBlock() {
    editor?.chain().focus().toggleCodeBlock().run()
  }

  export function setLink() {
    showLinkPopover = true
  }

  function insertLink() {
    if (linkUrl.trim()) {
      editor?.chain().focus().setLink({ href: linkUrl }).run()
      showLinkPopover = false
      linkUrl = ''
    }
  }

  function cancelLink() {
    showLinkPopover = false
    linkUrl = ''
    editor?.chain().focus().run()
  }
</script>

<div class="relative">
  <div
    bind:this={editorElement}
    class="tiptap-editor w-full h-full bg-transparent"
  ></div>

  {#if showLinkPopover}
    <div class="absolute top-0 left-0 mt-2 z-50 bg-base-200 border border-base-300 rounded-lg shadow-xl p-4 w-80">
      <div class="space-y-3">
        <div>
          <label class="label pb-1">
            <span class="label-text text-sm font-medium">Enter URL</span>
          </label>
          <input
            type="url"
            bind:this={linkInputRef}
            bind:value={linkUrl}
            placeholder="https://example.com"
            class="input input-bordered input-sm w-full"
            on:keydown={(e) => e.key === 'Enter' && insertLink()}
          />
        </div>
        <div class="flex justify-end gap-2">
          <button
            type="button"
            on:click={cancelLink}
            class="btn btn-ghost btn-sm"
          >
            Cancel
          </button>
          <button
            type="button"
            on:click={insertLink}
            class="btn btn-primary btn-sm"
            disabled={!linkUrl.trim()}
          >
            Insert Link
          </button>
        </div>
      </div>
    </div>
  {/if}
</div>

<style>
  :global(.tiptap-editor .ProseMirror) {
    height: 100%;
    outline: none;
  }

  :global(.tiptap-editor .ProseMirror p.is-editor-empty:first-child::before) {
    content: attr(data-placeholder);
    float: left;
    color: oklch(var(--bc) / 0.4);
    pointer-events: none;
    height: 0;
  }

  :global(.tiptap-editor .ProseMirror-focused) {
    outline: none;
  }

  /* Style code blocks */
  :global(.tiptap-editor pre) {
    background: oklch(var(--b3));
    border-radius: 0.5rem;
    color: oklch(var(--bc));
    font-family: 'JetBrains Mono', monospace;
    padding: 0.75rem 1rem;
    margin: 1rem 0;
  }

  :global(.tiptap-editor code) {
    background: oklch(var(--b3));
    border-radius: 0.25rem;
    color: oklch(var(--bc));
    font-size: 0.9rem;
    padding: 0.1em 0.3em;
  }

  /* Style blockquotes */
  :global(.tiptap-editor blockquote) {
    border-left: 3px solid oklch(var(--p));
    padding-left: 1rem;
    margin-left: 0;
    font-style: italic;
    opacity: 0.8;
  }
</style>
