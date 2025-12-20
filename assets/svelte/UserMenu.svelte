<script>
  import { LayoutDashboard, BookOpen, Bookmark, User, Settings, LogOut, Loader2 } from 'lucide-svelte'

  let { currentUser } = $props()

  let isLoggingOut = $state(false)

  function getUserInitials() {
    if (currentUser.name) {
      return currentUser.name
        .split(' ')
        .map(n => n.charAt(0))
        .join('')
        .toUpperCase()
        .slice(0, 2)
    }
    if (currentUser.email) {
      return currentUser.email.charAt(0).toUpperCase()
    }
    return 'U'
  }

  async function handleLogout() {
    if (isLoggingOut) return

    isLoggingOut = true

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
</script>

<div class="dropdown dropdown-end">
  <button
    tabindex="0"
    class="btn btn-ghost btn-circle avatar"
    aria-label="{currentUser.name || currentUser.email} account menu"
  >
    <div class="w-10 rounded-full">
      {#if currentUser.avatarUrl}
        <img
          src={currentUser.avatarUrl}
          alt={currentUser.name || currentUser.email}
        />
      {:else}
        <div class="avatar placeholder">
          <div class="bg-primary text-primary-content w-10 rounded-full">
            <span class="text-sm">{getUserInitials()}</span>
          </div>
        </div>
      {/if}
    </div>
  </button>

  <ul tabindex="0" class="menu dropdown-content bg-base-100 rounded-box z-[1] w-52 p-2 shadow mt-3">
    <li class="menu-title">
      <span>{currentUser.name || 'User'}</span>
      <span class="text-xs opacity-50">@{currentUser.username || currentUser.email?.split('@')[0] || 'user'}</span>
    </li>
    <li><div class="divider my-0"></div></li>
    <li>
      <a href="/">
        <LayoutDashboard class="w-4 h-4" />
        Dashboard
      </a>
    </li>
    <li>
      <a href="/lessons">
        <BookOpen class="w-4 h-4" />
        Courses
      </a>
    </li>
    <li>
      <a href="/romanov-prompts">
        <Bookmark class="w-4 h-4" />
        Saved
      </a>
    </li>
    <li>
      <a href={`/u/${currentUser.username}`}>
        <User class="w-4 h-4" />
        Profile
      </a>
    </li>
    <li>
      <a href={`/u/${currentUser.username}?tab=preferences&section=account`}>
        <Settings class="w-4 h-4" />
        Preferences
      </a>
    </li>
    <li><div class="divider my-0"></div></li>
    <li>
      <button onclick={handleLogout} disabled={isLoggingOut}>
        {#if isLoggingOut}
          <Loader2 class="w-4 h-4 animate-spin" />
          Logging out...
        {:else}
          <LogOut class="w-4 h-4" />
          Log out
        {/if}
      </button>
    </li>
  </ul>
</div>
