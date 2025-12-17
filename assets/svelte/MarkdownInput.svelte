<script>
  import { onMount, onDestroy } from 'svelte'
  import EasyMDE from 'easymde'

  export let value = ""
  export let placeholder = "Write your message..."
  export let minHeight = "200px"
  export let draftKey = null

  let editorElement
  let editor
  let autoSaveInterval = null

  onMount(() => {
    // Restore draft from localStorage if available
    let initialValue = value
    if (draftKey) {
      try {
        const draft = localStorage.getItem(draftKey)
        if (draft) {
          initialValue = draft
        }
      } catch (e) {
        console.warn('Failed to read draft from localStorage:', e)
      }
    }

    editor = new EasyMDE({
      element: editorElement,
      initialValue: initialValue,
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

    // Auto-save draft every 1 second if draftKey is provided
    if (draftKey) {
      autoSaveInterval = setInterval(() => {
        saveDraft()
      }, 1000)
    }
  })

  onDestroy(() => {
    if (autoSaveInterval) {
      clearInterval(autoSaveInterval)
    }
  })

  function saveDraft() {
    if (draftKey && editor) {
      try {
        const content = editor.value()
        if (content.trim()) {
          localStorage.setItem(draftKey, content)
        }
      } catch (e) {
        console.warn('Failed to save draft to localStorage:', e)
      }
    }
  }

  // Expose methods to parent
  export function getContent() {
    return editor ? editor.value() : value
  }

  export function clearDraft() {
    if (draftKey) {
      try {
        localStorage.removeItem(draftKey)
      } catch (e) {
        console.warn('Failed to clear draft:', e)
      }
    }
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
