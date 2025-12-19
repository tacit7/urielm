<script>
  import { Editor } from '@tiptap/core'
  import StarterKit from '@tiptap/starter-kit'
  import { onMount, onDestroy } from 'svelte'

  export let content = ''
  export let placeholder = 'Write something...'
  export let onUpdate = null
  export let onSelectionUpdate = null

  let editorElement
  let editor

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
    const url = window.prompt('Enter URL')
    if (url) {
      editor?.chain().focus().setLink({ href: url }).run()
    }
  }
</script>

<div
  bind:this={editorElement}
  class="tiptap-editor w-full h-full bg-transparent"
></div>

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
