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
  class="btn btn-ghost btn-circle swap swap-rotate size-11 text-base-content/65 transition duration-200 hover:bg-primary/10 hover:text-primary motion-reduce:transition-none"
  class:swap-active={currentTheme === DARK_THEME}
  aria-label={currentTheme === DARK_THEME ? 'Switch to Tokyo Day' : 'Switch to Tokyo Night'}
  title={currentTheme === DARK_THEME ? 'Switch to Tokyo Day' : 'Switch to Tokyo Night'}
>
  <UMIcon name="sun" className="swap-on size-4" />
  <UMIcon name="moon" className="swap-off size-4" />
</button>
