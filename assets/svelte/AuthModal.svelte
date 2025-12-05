<script>
  let { isOpen = $bindable(false) } = $props()

  const providers = [
    {
      name: 'Google',
      icon: '🔍',
      path: '/auth/google',
      colorClass: 'btn-neutral'
    },
    {
      name: 'Twitter',
      icon: '𝕏',
      path: '/auth/twitter',
      colorClass: 'btn-info'
    },
    {
      name: 'Facebook',
      icon: 'f',
      path: '/auth/facebook',
      colorClass: 'btn-primary'
    }
  ]

  function handleOAuthLogin(providerPath) {
    window.location.href = providerPath
  }

  function closeModal() {
    isOpen = false
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

    <h3 class="font-bold text-2xl mb-2">Welcome Back</h3>
    <p class="text-base-content/70 mb-6">Sign in to save prompts, leave comments, and more</p>

    <div class="flex flex-col gap-3">
      {#each providers as provider}
        <button
          onclick={() => handleOAuthLogin(provider.path)}
          class="btn {provider.colorClass} btn-lg w-full justify-start gap-4"
        >
          <span class="text-2xl">{provider.icon}</span>
          <span class="flex-1 text-left">Continue with {provider.name}</span>
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-5 w-5"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
          </svg>
        </button>
      {/each}
    </div>

    <div class="mt-6 text-xs text-base-content/50 text-center">
      By continuing, you agree to our Terms of Service and Privacy Policy
    </div>
  </div>
  <form method="dialog" class="modal-backdrop">
    <button onclick={closeModal}>close</button>
  </form>
</dialog>
