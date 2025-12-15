<script>
  const themes = [
    { value: 'light', label: 'Light', icon: '☀️' },
    { value: 'dark', label: 'Dark', icon: '🌙' },
    { value: 'tokyo-night', label: 'Tokyo Night', icon: '🗼' },
    { value: 'dracula', label: 'Dracula', icon: '🧛' },
    { value: 'synthwave', label: 'Synthwave', icon: '🌆' },
    { value: 'business', label: 'Business', icon: '💼' },
    { value: 'dim', label: 'Dim', icon: '🌑' }
  ]

  let currentTheme = $state('dark')
  let isOpen = $state(false)

  function applyTheme(theme) {
    currentTheme = theme
    if (theme === 'system') {
      document.documentElement.removeAttribute('data-theme')
      localStorage.removeItem('phx:theme')
    } else {
      document.documentElement.setAttribute('data-theme', theme)
      // Use the same storage key as Phoenix + other toggles
      localStorage.setItem('phx:theme', theme)
    }
    // Notify listeners (e.g., Phoenix head script)
    window.dispatchEvent(new CustomEvent('phx:set-theme', { detail: { theme } }))
  }

  function selectTheme(theme) {
    applyTheme(theme)
    isOpen = false
  }

  function toggleDropdown() {
    isOpen = !isOpen
  }

  // Close dropdown when clicking outside
  function handleClickOutside(event) {
    if (!event.target.closest('.theme-selector')) {
      isOpen = false
    }
  }

  $effect(() => {
    // Sync from page/head initialization
    const savedTheme = localStorage.getItem('phx:theme') || 'system'
    if (savedTheme === 'system') {
      currentTheme = document.documentElement.getAttribute('data-theme') || 'light'
    } else {
      currentTheme = savedTheme
    }

    // Keep in sync with other controls (Layouts.theme_toggle, other tabs)
    const storageHandler = (e) => {
      if (e.key === 'phx:theme') {
        const next = e.newValue || 'system'
        currentTheme = next === 'system' ? (document.documentElement.getAttribute('data-theme') || 'light') : next
      }
    }
    const themeEventHandler = (e) => {
      const next = e.detail?.theme ?? e.target?.dataset?.phxTheme ?? 'system'
      currentTheme = next === 'system' ? (document.documentElement.getAttribute('data-theme') || 'light') : next
    }

    document.addEventListener('click', handleClickOutside)
    window.addEventListener('storage', storageHandler)
    window.addEventListener('phx:set-theme', themeEventHandler)
    return () => {
      document.removeEventListener('click', handleClickOutside)
      window.removeEventListener('storage', storageHandler)
      window.removeEventListener('phx:set-theme', themeEventHandler)
    }
  })
</script>

<div class="theme-selector relative">
  <button
    onclick={toggleDropdown}
    class="btn btn-ghost btn-sm gap-2"
    aria-label="Select theme"
  >
    <span class="text-lg">{themes.find(t => t.value === currentTheme)?.icon || '🌙'}</span>
    <span class="hidden md:inline">Theme</span>
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class="h-4 w-4 transition-transform {isOpen ? 'rotate-180' : ''}"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
    >
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
    </svg>
  </button>

  {#if isOpen}
    <div class="absolute right-0 mt-2 w-48 bg-base-200 rounded-lg shadow-xl border border-base-300 z-50">
      <ul class="menu p-2">
        {#each themes as theme}
          <li>
            <button
              onclick={() => selectTheme(theme.value)}
              class="flex items-center gap-3 {currentTheme === theme.value ? 'active bg-primary text-primary-content' : ''}"
            >
              <span class="text-lg">{theme.icon}</span>
              <span>{theme.label}</span>
              {#if currentTheme === theme.value}
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4 ml-auto"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
              {/if}
            </button>
          </li>
        {/each}
      </ul>
    </div>
  {/if}
</div>

<style>
  .theme-selector {
    user-select: none;
  }
</style>
