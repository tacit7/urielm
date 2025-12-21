<script>
  import AuthModal from './AuthModal.svelte';
  import UserMenu from './UserMenu.svelte';

  let { currentPage = '', currentUser = null } = $props()

  let isScrolled = $state(false)
  let isMenuOpen = $state(false)
  let hideNavbar = $state(false)
  let showAuthModal = $state(false)
  let dropdownRef


  function handleScroll() {
    isScrolled = window.scrollY > 20
  }

  function toggleMenu() {
    isMenuOpen = !isMenuOpen
  }

  // Listen for composer fullscreen toggle
  $effect(() => {
    if (typeof window !== 'undefined') {
      const handler = (e) => {
        hideNavbar = e.detail.isFullscreen
      }
      window.addEventListener('composer-fullscreen', handler)
      return () => window.removeEventListener('composer-fullscreen', handler)
    }
  })

  function closeMenu() {
    isMenuOpen = false
  }

  function handleClickOutside(event) {
    if (dropdownRef && !dropdownRef.contains(event.target)) {
      closeMenu()
    }
  }

  $effect(() => {
    // run once on mount; re-run if handlers change (they don't)
    handleScroll()
    window.addEventListener('scroll', handleScroll)
    document.addEventListener('click', handleClickOutside)
    return () => {
      window.removeEventListener('scroll', handleScroll)
      document.removeEventListener('click', handleClickOutside)
    }
  })
</script>

<div
  class={`navbar fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
    isScrolled ? 'bg-base-100/80 backdrop-blur-md border-b border-base-300' : 'bg-transparent'
  } ${hideNavbar ? '-translate-y-full' : ''}`}
>
  <div class="navbar-start">
    <!-- Mobile Dropdown -->
    <div class="dropdown lg:hidden" class:dropdown-open={isMenuOpen} bind:this={dropdownRef}>
      <button
        onclick={toggleMenu}
        aria-label="Toggle navigation menu"
        aria-expanded={isMenuOpen}
        aria-controls="mobile-nav"
        class="btn btn-ghost"
      >
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
        </svg>
      </button>
      {#if isMenuOpen}
        <ul id="mobile-nav" class="menu menu-sm dropdown-content bg-base-100 rounded-box z-[1] mt-3 w-52 p-2 shadow">
          <li><a href="/courses" data-phx-link="patch" data-phx-link-state="push" class:active={currentPage === 'videos'} onclick={closeMenu}>Videos</a></li>
          <li><a href="/blog" data-phx-link="patch" data-phx-link-state="push" class:active={currentPage === 'blog'} onclick={closeMenu}>Blog</a></li>
          <li><a href="/prompts" data-phx-link="patch" data-phx-link-state="push" class:active={currentPage === 'prompts'} onclick={closeMenu}>Prompts</a></li>
          <li><a href="/forum" data-phx-link="patch" data-phx-link-state="push" class:active={currentPage === 'community'} onclick={closeMenu}>Community</a></li>
        </ul>
      {/if}
    </div>

    <!-- Logo -->
    <a href="/" data-phx-link="patch" data-phx-link-state="push" class="btn btn-ghost text-xl font-semibold tracking-tight">
      UrielM<span class="text-base-content/50">.dev</span>
    </a>
  </div>

  <!-- Desktop Navigation - Center -->
  <div class="navbar-center hidden lg:flex">
    <div class="flex items-center gap-8">
      <a
        href="/courses"
        data-phx-link="patch"
        data-phx-link-state="push"
        class={`font-medium transition-colors ${currentPage === 'videos' ? 'text-primary font-bold' : 'text-base-content hover:text-primary'}`}
      >
        Videos
      </a>
      <a
        href="/blog"
        data-phx-link="patch"
        data-phx-link-state="push"
        class={`font-medium transition-colors ${currentPage === 'blog' ? 'text-primary font-bold' : 'text-base-content hover:text-primary'}`}
      >
        Blog
      </a>
      <a
        href="/prompts"
        data-phx-link="patch"
        data-phx-link-state="push"
        class={`font-medium transition-colors ${currentPage === 'prompts' ? 'text-primary font-bold' : 'text-base-content hover:text-primary'}`}
      >
        Prompts
      </a>
      <a
        href="/forum"
        data-phx-link="patch"
        data-phx-link-state="push"
        class={`font-medium transition-colors ${currentPage === 'community' ? 'text-primary font-bold' : 'text-base-content hover:text-primary'}`}
      >
        Community
      </a>
    </div>
  </div>

  <!-- CTA Button - Right -->
  <div class="navbar-end gap-2">
    {#if currentUser}
      <UserMenu {currentUser} />
    {:else}
      <a
        href="/signin"
        class="btn btn-sm btn-ghost"
      >
        Sign In
      </a>
      <a
        href="/signup"
        class="btn btn-sm btn-primary rounded-full px-6"
      >
        Sign Up
      </a>
    {/if}
  </div>
</div>
