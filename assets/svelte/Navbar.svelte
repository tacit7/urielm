<script>
  import ThemeToggle from './ThemeToggle.svelte'
  import UMIcon from './UMIcon.svelte'
  import UserMenu from './UserMenu.svelte'
  import { pageForPath } from '../js/navigation.js'

  let { currentPage = '', currentUser = null } = $props()

  let browserPage = $state(null)
  let activePage = $derived(browserPage || currentPage || 'home')
  let isScrolled = $state(false)
  let isMenuOpen = $state(false)
  let hideNavbar = $state(false)
  let mobileMenuRef

  const navItems = [
    { page: 'videos', label: 'Courses', href: '/courses' },
    { page: 'blog', label: 'Blog', href: '/blog' },
    { page: 'prompts', label: 'Prompts', href: '/prompts' },
    { page: 'community', label: 'Community', href: '/forum' }
  ]

  function syncPage() {
    browserPage = pageForPath(window.location.pathname)
    isMenuOpen = false
  }

  function handleScroll() {
    isScrolled = window.scrollY > 16
  }

  function toggleMenu(event) {
    event.stopPropagation()
    isMenuOpen = !isMenuOpen
  }

  function closeMenu() {
    isMenuOpen = false
  }

  function handleClickOutside(event) {
    if (isMenuOpen && mobileMenuRef && !mobileMenuRef.contains(event.target)) closeMenu()
  }

  function handleKeydown(event) {
    if (event.key === 'Escape') closeMenu()
  }

  function desktopLinkClass(page) {
    return activePage === page
      ? 'bg-primary/10 text-primary'
      : 'text-base-content/65 hover:bg-base-200/70 hover:text-base-content'
  }

  function mobileLinkClass(page) {
    return activePage === page
      ? 'bg-primary/10 text-primary'
      : 'text-base-content/70 hover:bg-base-200 hover:text-base-content'
  }

  $effect(() => {
    const fullscreenHandler = (event) => {
      hideNavbar = event.detail.isFullscreen
    }

    handleScroll()
    syncPage()
    window.addEventListener('scroll', handleScroll, { passive: true })
    window.addEventListener('phx:page-loading-stop', syncPage)
    window.addEventListener('popstate', syncPage)
    window.addEventListener('composer-fullscreen', fullscreenHandler)
    document.addEventListener('click', handleClickOutside)
    document.addEventListener('keydown', handleKeydown)

    return () => {
      window.removeEventListener('scroll', handleScroll)
      window.removeEventListener('phx:page-loading-stop', syncPage)
      window.removeEventListener('popstate', syncPage)
      window.removeEventListener('composer-fullscreen', fullscreenHandler)
      document.removeEventListener('click', handleClickOutside)
      document.removeEventListener('keydown', handleKeydown)
    }
  })
</script>

<header
  id="global-navbar"
  class={`fixed inset-x-0 top-0 z-50 border-b transition duration-300 ${
    isScrolled
      ? 'border-base-300/70 bg-base-100/85 shadow-sm shadow-base-300/10 backdrop-blur-xl'
      : 'border-transparent bg-base-100/55 backdrop-blur-md'
  } ${hideNavbar ? '-translate-y-full' : ''}`}
>
  <nav class="navbar mx-auto min-h-16 max-w-7xl gap-2 px-4 sm:px-6 lg:px-8" aria-label="Primary navigation">
    <div class="navbar-start w-auto shrink-0">
      <a
        id="nav-brand"
        href="/"
        data-phx-link="redirect"
        data-phx-link-state="push"
        class="rounded-xl px-2 py-2 text-lg font-black tracking-[-0.04em] text-base-content transition hover:bg-base-200/70 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary sm:text-xl"
        onclick={closeMenu}
      >
        UrielM<span class="text-base-content/40">.dev</span>
      </a>
    </div>

    <div class="hidden flex-1 items-center pl-5 lg:flex">
      <div id="desktop-nav-links" class="flex items-center gap-1 rounded-2xl border border-base-300/45 bg-base-200/35 p-1">
        {#each navItems as item}
          <a
            href={item.href}
            data-phx-link="redirect"
            data-phx-link-state="push"
            data-nav-page={item.page}
            aria-current={activePage === item.page ? 'page' : undefined}
            class={`rounded-xl px-3.5 py-2 text-sm font-semibold transition duration-200 ${desktopLinkClass(item.page)}`}
          >
            {item.label}
          </a>
        {/each}
      </div>
    </div>

    <div class="navbar-end ml-auto w-auto gap-1 sm:gap-1.5">
      <a
        id="nav-search"
        href="/forum/search"
        class="btn btn-ghost btn-circle btn-sm hidden text-base-content/60 transition hover:bg-secondary/10 hover:text-secondary sm:inline-flex"
        aria-label="Search community"
        title="Search community"
      >
        <UMIcon name="search" className="size-4" />
      </a>

      <ThemeToggle />

      {#if currentUser}
        <UserMenu {currentUser} />
      {:else}
        <div class="hidden items-center gap-1.5 lg:flex">
          <a href="/signin" class="btn btn-ghost btn-sm rounded-full px-4 text-base-content/70">Sign in</a>
          <a href="/signup" class="btn btn-primary btn-sm rounded-full px-5 shadow-sm shadow-primary/15">Sign up</a>
        </div>
      {/if}

      <div class="relative lg:hidden" bind:this={mobileMenuRef}>
        <button
          id="mobile-menu-toggle"
          onclick={toggleMenu}
          aria-label={isMenuOpen ? 'Close navigation menu' : 'Open navigation menu'}
          aria-expanded={isMenuOpen}
          aria-controls="mobile-nav"
          class={`btn btn-ghost btn-circle btn-sm transition ${isMenuOpen ? 'bg-primary/10 text-primary' : 'text-base-content/70'}`}
        >
          <UMIcon name={isMenuOpen ? 'close' : 'bars_3'} className="size-5" />
        </button>

        {#if isMenuOpen}
          <div
            id="mobile-nav"
            class="absolute right-0 top-[calc(100%+0.85rem)] w-[min(22rem,calc(100vw-2rem))] overflow-hidden rounded-2xl border border-base-300/70 bg-base-100/95 p-2 shadow-2xl shadow-base-300/30 backdrop-blur-xl"
          >
            <div class="grid gap-1">
              {#each navItems as item}
                <a
                  href={item.href}
                  data-phx-link="redirect"
                  data-phx-link-state="push"
                  data-nav-page={item.page}
                  aria-current={activePage === item.page ? 'page' : undefined}
                  class={`group flex min-h-12 items-center justify-between rounded-xl px-4 text-sm font-bold transition ${mobileLinkClass(item.page)}`}
                  onclick={closeMenu}
                >
                  {item.label}
                  <UMIcon name="hero-arrow-right" className="size-4 opacity-45 transition group-hover:translate-x-0.5 group-hover:opacity-80" />
                </a>
              {/each}
            </div>

            <div class="my-2 h-px bg-base-300/60"></div>

            <a
              href="/forum/search"
              class="flex min-h-12 items-center gap-3 rounded-xl px-4 text-sm font-semibold text-base-content/65 transition hover:bg-secondary/10 hover:text-secondary"
              onclick={closeMenu}
            >
              <UMIcon name="search" className="size-4" />
              Search community
            </a>

            {#if currentUser}
              <a
                href={`/u/${currentUser.username}`}
                data-phx-link="redirect"
                data-phx-link-state="push"
                class="mt-1 flex min-h-12 items-center gap-3 rounded-xl px-4 text-sm font-semibold text-base-content/65 transition hover:bg-base-200 hover:text-base-content"
                onclick={closeMenu}
              >
                <UMIcon name="hero-user-circle" className="size-4" />
                View profile
              </a>
            {:else}
              <div class="grid grid-cols-2 gap-2 p-2 pt-3">
                <a href="/signin" class="btn btn-ghost btn-sm rounded-full">Sign in</a>
                <a href="/signup" class="btn btn-primary btn-sm rounded-full">Sign up</a>
              </div>
            {/if}
          </div>
        {/if}
      </div>
    </div>
  </nav>
</header>
