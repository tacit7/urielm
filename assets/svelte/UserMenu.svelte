<script>
  import UMIcon from './UMIcon.svelte'
  import { profilePathForUser } from '../js/navigation.js'

  let { currentUser } = $props()

  let isLoggingOut = $state(false)
  let isMenuOpen = $state(false)
  let menuRef
  let triggerRef
  let profilePath = $derived(profilePathForUser(currentUser))

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
    document.addEventListener('click', handleClickOutside)
    document.addEventListener('keydown', handleKeydown)

    return () => {
      document.removeEventListener('click', handleClickOutside)
      document.removeEventListener('keydown', handleKeydown)
    }
  })
</script>

<div class="dropdown dropdown-end relative" bind:this={menuRef}>
  <button
    id="account-menu-toggle"
    bind:this={triggerRef}
    onclick={toggleMenu}
    class={`btn btn-ghost btn-circle avatar size-11 transition ${isMenuOpen ? 'bg-primary/10 ring-2 ring-primary/30' : ''}`}
    aria-label={`${currentUser.name || currentUser.email} account menu`}
    aria-expanded={isMenuOpen}
    aria-controls="account-menu"
  >
    <div class="w-10 rounded-full">
      {#if currentUser.avatarUrl}
        <img src={currentUser.avatarUrl} alt="" />
      {:else}
        <div class="avatar placeholder">
          <div class="w-10 rounded-full bg-primary text-primary-content">
            <span class="text-sm font-bold">{getUserInitials()}</span>
          </div>
        </div>
      {/if}
    </div>
  </button>

  {#if isMenuOpen}
    <ul
      id="account-menu"
      class="menu dropdown-content absolute right-0 top-[calc(100%+0.75rem)] z-50 w-72 gap-1 rounded-2xl bg-base-200 p-2 shadow-xl"
    >
      <li class="pointer-events-none px-3 pb-2 pt-2">
        <span class="block p-0 text-sm font-bold text-base-content">
          {currentUser.name || 'Your account'}
        </span>
        <span class="mt-0.5 block truncate p-0 text-xs font-medium text-base-content/50">
          {currentUser.email || `@${currentUser.username}`}
        </span>
      </li>
      <li class="border-t border-base-300/60 pt-1">
        <a href={profilePath} data-phx-link="redirect" data-phx-link-state="push" onclick={closeMenu}>
          <UMIcon name="hero-user-circle" className="size-4" />
          Profile
        </a>
      </li>
      <li>
        <a href="/saved" data-phx-link="redirect" data-phx-link-state="push" onclick={closeMenu}>
          <UMIcon name="hero-bookmark" className="size-4" />
          Saved items
        </a>
      </li>
      <li>
        <a href="/settings" data-phx-link="redirect" data-phx-link-state="push" onclick={closeMenu}>
          <UMIcon name="hero-cog-6-tooth" className="size-4" />
          Settings
        </a>
      </li>
      <li class="mt-1 border-t border-base-300/60 pt-1">
        <button
          type="button"
          class="text-error hover:bg-error/10 hover:text-error"
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
