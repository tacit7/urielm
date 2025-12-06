<script>
  let { isOpen = $bindable(false), live } = $props()

  let mode = $state('signin') // 'signin' or 'signup'
  let email = $state('')
  let password = $state('')
  let name = $state('')
  let error = $state('')
  let loading = $state(false)

  function handleOAuthLogin() {
    window.location.href = '/auth/google'
  }

  function closeModal() {
    isOpen = false
    email = ''
    password = ''
    name = ''
    error = ''
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
        : { email, password, name }

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
        ✕
      </button>
    </form>

    <h3 class="font-bold text-2xl mb-2">{mode === 'signin' ? 'Welcome Back' : 'Create Account'}</h3>
    <p class="text-base-content/70 mb-6">
      {mode === 'signin' ? 'Sign in to save prompts, leave comments, and more' : 'Join to unlock all features'}
    </p>

    <!-- Google OAuth -->
    <button
      onclick={handleOAuthLogin}
      class="btn btn-neutral btn-lg w-full justify-start gap-4 mb-4"
    >
      <span class="text-2xl">🔍</span>
      <span class="flex-1 text-left">Continue with Google</span>
    </button>

    <!-- Divider -->
    <div class="divider text-xs text-base-content/50">or</div>

    <!-- Email/Password Form -->
    <form onsubmit={handleEmailAuth} class="flex flex-col gap-4">
      {#if mode === 'signup'}
        <div class="form-control w-full">
          <label class="label flex-col items-start gap-1" for="name">
            <span class="label-text">Name</span>
            <input
              id="name"
              type="text"
              bind:value={name}
              placeholder="Your name"
              class="input input-bordered w-full"
              required
              disabled={loading}
            />
          </label>
        </div>
      {/if}

      <div class="form-control w-full">
        <label class="label flex-col items-start gap-1" for="email">
          <span class="label-text">Email</span>
          <input
            id="email"
            type="email"
            bind:value={email}
            placeholder="you@example.com"
            class="input input-bordered w-full"
            required
            disabled={loading}
          />
        </label>
      </div>

      <div class="form-control w-full">
        <label class="label flex-col items-start gap-1" for="password">
          <span class="label-text">Password</span>
          <input
            id="password"
            type="password"
            bind:value={password}
            placeholder="••••••••"
            class="input input-bordered w-full"
            required
            minlength="8"
            disabled={loading}
          />
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
