<script>
  import UMIcon from './UMIcon.svelte'
  import { DARK_THEME, normalizeTheme, oppositeTheme } from '../js/theme.js'

  let currentTheme = $state(DARK_THEME)

  function toggleTheme() {
    const newTheme = oppositeTheme(currentTheme)
    currentTheme = newTheme
    window.dispatchEvent(new CustomEvent('phx:set-theme', {
      detail: { theme: newTheme }
    }))
  }

  $effect(() => {
    currentTheme = normalizeTheme(
      localStorage.getItem('phx:theme') || document.documentElement.dataset.theme
    )

    const syncTheme = (event) => {
      const nextTheme = event.detail?.theme ?? event.newValue
      currentTheme = normalizeTheme(nextTheme)
    }

    window.addEventListener('phx:set-theme', syncTheme)
    window.addEventListener('storage', syncTheme)
    return () => {
      window.removeEventListener('phx:set-theme', syncTheme)
      window.removeEventListener('storage', syncTheme)
    }
  })
</script>

<button
  id="tokyo-theme-toggle"
  onclick={toggleTheme}
  class="btn btn-ghost btn-circle btn-sm text-base-content/65 transition duration-200 hover:rotate-6 hover:bg-primary/10 hover:text-primary"
  aria-label={currentTheme === DARK_THEME ? 'Switch to Tokyo Day' : 'Switch to Tokyo Night'}
  title={currentTheme === DARK_THEME ? 'Switch to Tokyo Day' : 'Switch to Tokyo Night'}
>
  {#if currentTheme === DARK_THEME}
    <UMIcon name="sun" className="size-4" />
  {:else}
    <UMIcon name="moon" className="size-4" />
  {/if}
</button>
