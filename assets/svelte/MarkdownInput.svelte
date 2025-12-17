<script>
  import { onMount } from 'svelte'
  import EasyMDE from 'easymde'

  export let value = ""
  export let placeholder = "Write your message..."
  export let minHeight = "200px"

  let editorElement
  let editor

  onMount(() => {
    editor = new EasyMDE({
      element: editorElement,
      initialValue: value,
      placeholder: placeholder,
      spellChecker: false,
      autoDownloadFontAwesome: false,
      minHeight: minHeight,
      toolbar: [
        'bold',
        'italic',
        'heading',
        '|',
        'quote',
        'unordered-list',
        'ordered-list',
        '|',
        'link',
        'image',
        'code',
        '|',
        'preview',
        'side-by-side',
        'fullscreen',
        '|',
        'guide'
      ],
      shortcuts: {
        toggleBold: 'Ctrl-B',
        toggleItalic: 'Ctrl-I',
        toggleCodeBlock: 'Ctrl-Alt-C',
        drawLink: 'Ctrl-K',
        drawImage: 'Ctrl-Alt-I',
        drawHorizontalRule: 'Ctrl-H',
        undo: 'Ctrl-Z',
        redo: 'Ctrl-Y',
        toggleUnorderedList: 'Ctrl-Alt-L',
        toggleOrderedList: 'Ctrl-Alt-O',
        togglePreview: 'Ctrl-P',
        toggleSideBySide: 'Ctrl-Alt-P',
        toggleFullScreen: 'F11'
      }
    })

    // Update parent value on change
    editor.codemirror.on('change', () => {
      value = editor.value()
    })
  })

  // Expose getter to parent
  export function getContent() {
    return editor ? editor.value() : value
  }

  // Update editor when value prop changes (for edit mode)
  $: if (editor && value !== editor.value()) {
    editor.value(value)
  }
</script>

<div class="markdown-editor">
  <textarea bind:this={editorElement}></textarea>
</div>

<style>
  :global(.CodeMirror) {
    font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
    font-size: 14px;
  }

  :global(.editor-preview) {
    background-color: var(--base-100);
    color: var(--base-content);
  }

  :global(.editor-toolbar) {
    background-color: var(--base-200);
    border-color: var(--base-300);
  }

  :global(.editor-toolbar button) {
    color: var(--base-content);
  }

  :global(.editor-toolbar button:hover) {
    background-color: var(--base-300);
  }

  :global(.editor-preview-side) {
    border-left-color: var(--base-300);
  }
</style>
