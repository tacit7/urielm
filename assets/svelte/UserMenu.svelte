<script>
  let { currentUser } = $props()

  let isOpen = $state(false)

  function toggleMenu() {
    isOpen = !isOpen
  }

  function closeMenu() {
    isOpen = false
  }

  function handleClickOutside(event) {
    if (!event.target.closest('.dropdown')) {
      closeMenu()
    }
  }

  function handleLogout() {
    // Create a form and submit it to perform DELETE request
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
    return () => {
      document.removeEventListener('click', handleClickOutside)
    }
  })
</script>

<div class="dropdown dropdown-end" class:dropdown-open={isOpen}>
  <button
    onclick={toggleMenu}
    class="btn btn-ghost btn-circle avatar online"
    aria-label="User menu"
  >
    {#if currentUser.avatarUrl}
      <div class="w-10 rounded-full ring ring-primary ring-offset-base-100 ring-offset-2">
        <img
          src={currentUser.avatarUrl}
          alt={currentUser.name || currentUser.email}
        />
      </div>
    {:else}
      <div class="w-10 h-10 rounded-full bg-primary flex items-center justify-center text-primary-content font-bold ring ring-primary ring-offset-base-100 ring-offset-2">
        {currentUser.name?.charAt(0).toUpperCase() || currentUser.email?.charAt(0).toUpperCase() || 'U'}
      </div>
    {/if}
  </button>

  {#if isOpen}
    <ul class="menu dropdown-content bg-base-200 rounded-box z-[1] w-52 p-2 shadow-xl border border-base-300 mt-3">
      <li class="menu-title px-4 py-2">
        <div class="flex flex-col">
          <span class="font-semibold text-base-content">{currentUser.name || 'User'}</span>
          <span class="text-xs text-base-content/60">{currentUser.email}</span>
        </div>
      </li>
      <li>
        <a href="/saved" onclick={closeMenu}>
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z" />
          </svg>
          My Saved
        </a>
      </li>
      <li>
        <button onclick={handleLogout}>
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
          </svg>
          Sign Out
        </button>
      </li>
    </ul>
  {/if}
</div>
