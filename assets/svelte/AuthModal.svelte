<script>
  import { Eye, EyeOff, X, CheckCircle, AlertCircle } from 'lucide-svelte'
  import GoogleSignInButton from './GoogleSignInButton.svelte'

  let { isOpen = $bindable(false), live } = $props()

  let mode = $state('signin') // 'signin' or 'signup'
  let email = $state('')
  let password = $state('')
  let username = $state('')
  let displayName = $state('')
  let error = $state('')
  let loading = $state(false)
  let showPassword = $state(false)
  let handleStatus = $state(null) // null, 'valid', 'taken', 'invalid'
  let handleCheckLoading = $state(false)
  let checkTimeout = null

  const HANDLE_PATTERN = /^(?=.{3,20}$)[a-z0-9]+([_-][a-z0-9]+)*$/

  function normalizeHandle(value) {
    return value
      .toLowerCase()
      .trim()
      .replace(/\s+/g, '_')
      .replace(/[^a-z0-9_-]/g, '')
  }

  function validateHandleFormat(value) {
    return HANDLE_PATTERN.test(value)
  }

  function onHandleInput(e) {
    username = normalizeHandle(e.target.value)

    if (checkTimeout) clearTimeout(checkTimeout)

    if (!username) {
      handleStatus = null
      return
    }

    if (!validateHandleFormat(username)) {
      handleStatus = 'invalid'
      return
    }

    handleStatus = null
    handleCheckLoading = true

    checkTimeout = setTimeout(async () => {
      try {
        const response = await fetch(`/api/check-handle?username=${encodeURIComponent(username)}`)
        const data = await response.json()
        handleStatus = data.available ? 'valid' : 'taken'
      } catch (e) {
        handleStatus = null
      } finally {
        handleCheckLoading = false
      }
    }, 300)
  }

  function closeModal() {
    isOpen = false
    email = ''
    password = ''
    username = ''
    displayName = ''
    error = ''
    showPassword = false
    handleStatus = null
    if (checkTimeout) clearTimeout(checkTimeout)
  }

  function switchMode() {
    mode = mode === 'signin' ? 'signup' : 'signin'
    error = ''
  }

  async function handleEmailAuth(event) {
    event.preventDefault()
    error = ''
    loading = true

    try {
      const endpoint = mode === 'signin' ? '/auth/signin' : '/auth/signup'
      const body = mode === 'signin'
        ? { email, password }
        : { email, password, username, displayName }

      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content || ''
        },
        body: JSON.stringify(body)
      })

      if (response.ok) {
        window.location.reload()
      } else {
        const data = await response.json()
        error = data.error || 'Authentication failed'
      }
    } catch (e) {
      error = 'Network error. Please try again.'
    } finally {
      loading = false
    }
  }
</script>

<dialog class="modal" class:modal-open={isOpen}>
  <div class="modal-box bg-base-200 max-w-md">
    <form method="dialog">
      <button
        onclick={closeModal}
        class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2"
        aria-label="Close"
      >
        <X class="w-4 h-4" />
      </button>
    </form>

    <h3 class="font-bold text-2xl mb-2">{mode === 'signin' ? 'Welcome Back' : 'Create Account'}</h3>
    <p class="text-base-content/70 mb-6">
      {mode === 'signin' ? 'Sign in to save prompts, leave comments, and more' : 'Join to unlock all features'}
    </p>

    <!-- Google OAuth -->
    <GoogleSignInButton disabled={loading} />

    <!-- Divider -->
    <div class="divider text-xs text-base-content/50">or</div>

    <!-- Email/Password Form -->
    <form onsubmit={handleEmailAuth} class="flex flex-col gap-4">
      {#if mode === 'signup'}
        <div class="form-control w-full">
          <label class="label pb-1" for="username">
            <span class="label-text text-sm">Handle</span>
          </label>
          <input
            id="username"
            type="text"
            oninput={onHandleInput}
            value={username}
            placeholder="lowercase-handle"
            class="input input-bordered w-full"
            required
            disabled={loading}
            autocomplete="off"
          />
          <div class="mt-1 flex items-center gap-2">
            {#if handleCheckLoading}
              <span class="loading loading-spinner loading-sm"></span>
              <span class="text-xs text-base-content/60">Checking availability...</span>
            {:else if handleStatus === 'valid'}
              <CheckCircle class="w-4 h-4 text-success" />
              <span class="text-xs text-success">Available</span>
            {:else if handleStatus === 'taken'}
              <AlertCircle class="w-4 h-4 text-warning" />
              <span class="text-xs text-warning">Taken</span>
            {:else if handleStatus === 'invalid'}
              <AlertCircle class="w-4 h-4 text-error" />
              <span class="text-xs text-error">Only letters, numbers, dashes/underscores; 3-20 chars</span>
            {/if}
          </div>
        </div>

        <div class="form-control w-full">
          <label class="label pb-1" for="displayName">
            <span class="label-text text-sm">Display Name</span>
          </label>
          <input
            id="displayName"
            type="text"
            bind:value={displayName}
            placeholder="Your Name"
            class="input input-bordered w-full"
            required
            disabled={loading}
            maxlength="50"
          />
          <p class="text-xs text-base-content/50 mt-1">Shows on your profile and comments</p>
        </div>
      {/if}

      <div class="form-control w-full">
        <label class="label pb-1" for="email">
          <span class="label-text text-sm">Email</span>
        </label>
        <input
          id="email"
          type="email"
          bind:value={email}
          placeholder="you@example.com"
          class="input input-bordered w-full"
          required
          disabled={loading}
        />
      </div>

      <div class="form-control w-full">
        <label class="label pb-1" for="password">
          <span class="label-text text-sm">Password</span>
        </label>
        <label class="input input-bordered w-full flex items-center gap-2">
          <input
            id="password"
            type={showPassword ? 'text' : 'password'}
            bind:value={password}
            placeholder="••••••••"
            class="grow bg-transparent outline-none"
            required
            minlength="8"
            disabled={loading}
          />
          <button
            type="button"
            onclick={() => showPassword = !showPassword}
            class="btn btn-ghost btn-xs btn-circle"
            aria-label={showPassword ? 'Hide password' : 'Show password'}
          >
            {#if showPassword}
              <Eye class="w-4 h-4" />
            {:else}
              <EyeOff class="w-4 h-4" />
            {/if}
          </button>
        </label>
      </div>

      {#if error}
        <div class="alert alert-error text-sm">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
          <span>{error}</span>
        </div>
      {/if}

      <button type="submit" class="btn btn-primary btn-lg w-full" disabled={loading}>
        {#if loading}
          <span class="loading loading-spinner"></span>
          Loading...
        {:else}
          {mode === 'signin' ? 'Sign In' : 'Sign Up'}
        {/if}
      </button>
    </form>

    <!-- Switch mode -->
    <div class="mt-4 text-center text-sm">
      <span class="text-base-content/70">
        {mode === 'signin' ? "Don't have an account?" : 'Already have an account?'}
      </span>
      <button onclick={switchMode} class="link link-primary ml-1">
        {mode === 'signin' ? 'Sign up' : 'Sign in'}
      </button>
    </div>

    <div class="mt-6 text-xs text-base-content/50 text-center">
      By continuing, you agree to our Terms of Service and Privacy Policy
    </div>
  </div>
  <form method="dialog" class="modal-backdrop">
    <button onclick={closeModal}>close</button>
  </form>
</dialog>
