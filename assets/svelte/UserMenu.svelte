<script>
  import UMIcon from './UMIcon.svelte'
  import { profilePathForUser } from '../js/navigation.js'
  import { DARK_THEME, LIGHT_THEME, normalizeTheme } from '../js/theme.js'

  let { currentUser } = $props()

  let isLoggingOut = $state(false)
  let isMenuOpen = $state(false)
  let currentTheme = $state(DARK_THEME)
  let menuRef = $state()
  let triggerRef = $state()
  let profilePath = $derived(profilePathForUser(currentUser))
  let themeEnabled = $derived(currentTheme === DARK_THEME)

  function getUserInitials() {
    if (currentUser.name) {
      return currentUser.name
        .split(' ')
        .map((name) => name.charAt(0))
        .join('')
        .toUpperCase()
        .slice(0, 2)
    }

    return currentUser.email?.charAt(0).toUpperCase() || 'U'
  }

  function toggleMenu(event) {
    event.stopPropagation()
    isMenuOpen = !isMenuOpen
  }

  function closeMenu() {
    isMenuOpen = false
  }

  function closeMenuAndRestoreFocus() {
    closeMenu()
    requestAnimationFrame(() => triggerRef?.focus())
  }

  function handleClickOutside(event) {
    if (isMenuOpen && menuRef && !menuRef.contains(event.target)) closeMenu()
  }

  function handleKeydown(event) {
    if (event.key === 'Escape' && isMenuOpen) closeMenuAndRestoreFocus()
  }

  function setTheme(theme) {
    currentTheme = normalizeTheme(theme)
    window.dispatchEvent(new CustomEvent('phx:set-theme', { detail: { theme: currentTheme } }))
  }

  async function handleLogout() {
    if (isLoggingOut) return

    isLoggingOut = true

    const form = document.createElement('form')
    form.method = 'POST'
    form.action = '/auth/logout'

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    if (csrfToken) {
      const csrfInput = document.createElement('input')
      csrfInput.type = 'hidden'
      csrfInput.name = '_csrf_token'
      csrfInput.value = csrfToken
      form.appendChild(csrfInput)
    }

    const methodInput = document.createElement('input')
    methodInput.type = 'hidden'
    methodInput.name = '_method'
    methodInput.value = 'DELETE'
    form.appendChild(methodInput)

    document.body.appendChild(form)
    form.submit()
  }

  $effect(() => {
    currentTheme = normalizeTheme(
      localStorage.getItem('phx:theme') || document.documentElement.dataset.theme,
    )

    const syncTheme = (event) => {
      const nextTheme = event.detail?.theme ?? event.newValue
      currentTheme = normalizeTheme(nextTheme)
    }

    document.addEventListener('click', handleClickOutside)
    document.addEventListener('keydown', handleKeydown)
    window.addEventListener('phx:set-theme', syncTheme)
    window.addEventListener('storage', syncTheme)

    return () => {
      document.removeEventListener('click', handleClickOutside)
      document.removeEventListener('keydown', handleKeydown)
      window.removeEventListener('phx:set-theme', syncTheme)
      window.removeEventListener('storage', syncTheme)
    }
  })
</script>

<div class="dropdown dropdown-end relative" bind:this={menuRef}>
  <button
    id="account-menu-toggle"
    bind:this={triggerRef}
    onclick={toggleMenu}
    class={`group inline-flex size-10 items-center justify-center rounded-full border p-0 shadow-sm shadow-black/10 transition focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary ${
      isMenuOpen
        ? 'border-primary/45 bg-primary/10 text-primary ring-2 ring-primary/20'
        : 'border-base-300/70 bg-base-200/80 text-base-content/80 hover:border-primary/35 hover:bg-primary/10 hover:text-primary'
    }`}
    aria-label={`${currentUser.name || currentUser.email} account menu`}
    aria-expanded={isMenuOpen}
    aria-controls="account-menu"
  >
    {#if currentUser.avatarUrl}
      <img src={currentUser.avatarUrl} alt="" class="size-8 rounded-full object-cover ring-1 ring-base-100/70" />
    {:else}
      <span class="inline-flex size-8 items-center justify-center rounded-full bg-base-300/75 text-xs font-black leading-none text-base-content shadow-inner shadow-black/10 transition group-hover:bg-primary/15 group-hover:text-primary">
        {getUserInitials()}
      </span>
    {/if}
  </button>

  {#if isMenuOpen}
    <ul
      id="account-menu"
      class="menu dropdown-content absolute right-0 top-[calc(100%+0.75rem)] z-50 w-[min(18rem,calc(100vw-2rem))] gap-1 rounded-2xl bg-base-200 p-2 shadow-xl"
    >
      <li class="pointer-events-none px-3 pb-2 pt-2">
        <div class="flex min-w-0 items-center gap-3 p-0">
          <div class="flex size-9 shrink-0 items-center justify-center overflow-hidden rounded-full bg-primary text-sm font-black text-primary-content">
            {#if currentUser.avatarUrl}
              <img src={currentUser.avatarUrl} alt="" class="size-full object-cover" />
            {:else}
              {getUserInitials()}
            {/if}
          </div>
          <div class="min-w-0">
            <span class="block truncate p-0 text-sm font-bold text-base-content">
              {currentUser.name || currentUser.username || 'Your account'}
            </span>
            <span class="mt-0.5 block truncate p-0 text-xs font-medium text-base-content/50">
              {currentUser.email || `@${currentUser.username}`}
            </span>
          </div>
        </div>
      </li>
      <li class="border-t border-base-300/60 pt-1">
        <a
          href={profilePath}
          data-phx-link="redirect"
          data-phx-link-state="push"
          class="min-h-10 gap-3 rounded-xl px-3 text-sm font-semibold text-base-content/70 hover:bg-base-100/70 hover:text-base-content"
          onclick={closeMenu}
        >
          <UMIcon name="hero-user-circle" className="size-4" />
          My Profile
        </a>
      </li>
      <li>
        <a
          href="/saved"
          data-phx-link="redirect"
          data-phx-link-state="push"
          class="min-h-10 gap-3 rounded-xl px-3 text-sm font-semibold text-base-content/70 hover:bg-base-100/70 hover:text-base-content"
          onclick={closeMenu}
        >
          <UMIcon name="hero-bookmark" className="size-4" />
          Saved items
        </a>
      </li>
      <li>
        <a
          href="/settings"
          data-phx-link="redirect"
          data-phx-link-state="push"
          class="min-h-10 gap-3 rounded-xl px-3 text-sm font-semibold text-base-content/70 hover:bg-base-100/70 hover:text-base-content"
          onclick={closeMenu}
        >
          <UMIcon name="hero-cog-6-tooth" className="size-4" />
          Settings
        </a>
      </li>
      <li>
        <button
          type="button"
          class="min-h-10 gap-3 rounded-xl px-3 text-sm font-semibold text-base-content/70 hover:bg-base-100/70 hover:text-base-content"
          onclick={() => setTheme(themeEnabled ? LIGHT_THEME : DARK_THEME)}
        >
          <UMIcon name={themeEnabled ? 'hero-moon' : 'hero-sun'} className="size-4" />
          Theme
        </button>
      </li>
      <li class="mt-1 border-t border-base-300/60 pt-1">
        <button
          type="button"
          class="min-h-10 gap-3 rounded-xl px-3 text-sm font-semibold text-error hover:bg-error/10 hover:text-error"
          onclick={handleLogout}
          disabled={isLoggingOut}
        >
          {#if isLoggingOut}
            <UMIcon name="hero-arrow-path" className="size-4 animate-spin motion-reduce:animate-none" />
            Logging out…
          {:else}
            <UMIcon name="hero-arrow-right-start-on-rectangle" className="size-4" />
            Log out
          {/if}
        </button>
      </li>
    </ul>
  {/if}
</div>
