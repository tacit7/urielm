<script>
  import UMIcon from './UMIcon.svelte'
  import UserMenu from './UserMenu.svelte'
  import { mobileMoreItems, pageForPath, primaryNavItems } from '../js/navigation.js'

  let {
    currentPage = '',
    currentUser = null,
    unreadNotificationCount = 0,
    showNavLinks = true,
    newTopicPath = null,
    drawerId = null,
  } = $props()

  let browserPage = $state(null)
  let activePage = $derived(browserPage || currentPage || 'home')
  let pushedUnreadCount = $state(null)
  let unreadCount = $derived(
    pushedUnreadCount === null
      ? Math.max(0, Number(unreadNotificationCount) || 0)
      : pushedUnreadCount,
  )
  let isScrolled = $state(false)
  let isMenuOpen = $state(false)
  let isNotificationsOpen = $state(false)
  let hideNavbar = $state(false)
  let mobileMenuRef = $state()
  let mobileTriggerRef = $state()
  let notificationsMenuRef = $state()
  let notificationsTriggerRef = $state()

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

  function toggleNotifications(event) {
    event.stopPropagation()
    isNotificationsOpen = !isNotificationsOpen
    isMenuOpen = false
  }

  function closeNotifications() {
    isNotificationsOpen = false
  }

  function closeNotificationsAndRestoreFocus() {
    closeNotifications()
    requestAnimationFrame(() => notificationsTriggerRef?.focus())
  }

  function closeMenuAndRestoreFocus() {
    closeMenu()
    requestAnimationFrame(() => mobileTriggerRef?.focus())
  }

  function handleClickOutside(event) {
    if (isMenuOpen && mobileMenuRef && !mobileMenuRef.contains(event.target)) closeMenu()
    if (
      isNotificationsOpen &&
      notificationsMenuRef &&
      !notificationsMenuRef.contains(event.target)
    ) closeNotifications()
  }

  function handleKeydown(event) {
    if (event.key === 'Escape' && isMenuOpen) closeMenuAndRestoreFocus()
    if (event.key === 'Escape' && isNotificationsOpen) closeNotificationsAndRestoreFocus()
  }

  function syncUnreadCount(event) {
    pushedUnreadCount = Math.max(0, Number(event.detail?.count) || 0)
  }

  function desktopLinkClass(page) {
    return activePage === page
      ? 'bg-primary/10 text-primary after:absolute after:inset-x-3 after:bottom-1 after:h-0.5 after:rounded-full after:bg-primary'
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
    window.addEventListener('phx:unread-notification-count', syncUnreadCount)
    document.addEventListener('click', handleClickOutside)
    document.addEventListener('keydown', handleKeydown)

    return () => {
      window.removeEventListener('scroll', handleScroll)
      window.removeEventListener('phx:page-loading-stop', syncPage)
      window.removeEventListener('popstate', syncPage)
      window.removeEventListener('composer-fullscreen', fullscreenHandler)
      window.removeEventListener('phx:unread-notification-count', syncUnreadCount)
      document.removeEventListener('click', handleClickOutside)
      document.removeEventListener('keydown', handleKeydown)
    }
  })
</script>

<header
  id="global-navbar"
  class={`fixed inset-x-0 top-0 z-50 border-b transition duration-200 motion-reduce:transition-none ${
    isScrolled
      ? 'border-base-300/70 bg-base-100/85 shadow-sm shadow-base-300/10 backdrop-blur-xl'
      : 'border-transparent bg-base-100/55 backdrop-blur-md'
  } ${hideNavbar ? '-translate-y-full' : ''}`}
>
  <nav class="navbar relative mx-auto min-h-14 max-w-7xl gap-2 px-4 py-1 sm:px-6 lg:px-8" aria-label="Primary navigation">
    <div class="navbar-start w-auto shrink-0 gap-1.5">
      {#if drawerId}
        <label
          id="forum-sidebar-toggle"
          for={drawerId}
          class="btn btn-ghost btn-circle size-11 text-base-content/70 transition hover:bg-primary/10 hover:text-primary lg:hidden"
          aria-label="Open community navigation"
        >
          <UMIcon name="bars_3" className="size-5" />
        </label>
      {/if}

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

    {#if showNavLinks}
    <div class="navbar-center absolute left-1/2 hidden -translate-x-1/2 lg:flex">
      <ul id="desktop-nav-links" class="menu menu-horizontal flex-nowrap gap-0.5 p-0">
        {#each primaryNavItems as item}
          <li>
            <a
              href={item.href}
              data-phx-link="redirect"
              data-phx-link-state="push"
              data-nav-page={item.page}
              aria-current={activePage === item.page ? 'page' : undefined}
              class={`relative flex min-h-11 items-center rounded-xl px-3.5 text-sm font-semibold transition duration-200 motion-reduce:transition-none ${desktopLinkClass(item.page)}`}
            >
              {item.label}
            </a>
          </li>
        {/each}
      </ul>
    </div>
    {/if}

    <div class="navbar-end ml-auto w-auto gap-1 sm:gap-1.5">
      {#if newTopicPath}
        <a
          id="nav-new-topic"
          href={newTopicPath}
          data-phx-link="redirect"
          data-phx-link-state="push"
          class="btn btn-primary btn-sm h-9 min-h-9 rounded-full px-3 text-xs font-black shadow-sm shadow-primary/15 sm:px-4"
        >
          <UMIcon name="hero-plus" className="size-4" />
          <span class="hidden sm:inline">New topic</span>
        </a>
      {/if}

      <a
        id="nav-search"
        href="/forum/search"
        class="btn btn-ghost btn-circle size-11 text-base-content/60 transition hover:bg-primary/10 hover:text-primary"
        aria-label="Search community"
        title="Search community"
      >
        <UMIcon name="search" className="size-4" />
      </a>

      {#if currentUser}
        <div
          class={`dropdown dropdown-end relative ${showNavLinks ? 'hidden lg:block' : 'block'}`}
          class:dropdown-open={isNotificationsOpen}
          bind:this={notificationsMenuRef}
        >
          <button
            id="nav-notifications"
            bind:this={notificationsTriggerRef}
            type="button"
            onclick={toggleNotifications}
            class={`btn btn-ghost btn-circle relative size-11 text-base-content/60 transition hover:bg-info/10 hover:text-info ${isNotificationsOpen ? 'bg-info/10 text-info' : ''}`}
            aria-label={unreadCount > 0 ? `${unreadCount} unread notifications` : 'Notifications'}
            aria-expanded={isNotificationsOpen}
            aria-controls="notification-menu"
            title="Notifications"
          >
            <UMIcon name="bell" className="size-4" />
            {#if unreadCount > 0}
              <span
                id="nav-notification-badge"
                class="badge badge-info absolute -right-1 -top-1 h-5 min-w-5 border-2 border-base-100 px-1 text-xs font-black text-info-content"
              >
                {unreadCount > 99 ? '99+' : unreadCount}
              </span>
            {/if}
          </button>

          {#if isNotificationsOpen}
            <div
              id="notification-menu"
              class="dropdown-content absolute right-0 top-[calc(100%+0.75rem)] z-50 w-[min(20rem,calc(100vw-2rem))] overflow-hidden rounded-2xl bg-base-200 p-2 shadow-xl"
            >
              <div class="flex items-center justify-between gap-3 px-3 pb-2 pt-2">
                <div>
                  <p class="text-sm font-black text-base-content">Notifications</p>
                  <p class="mt-0.5 text-xs font-medium text-base-content/45">
                    {#if unreadCount > 0}
                      {unreadCount} unread {unreadCount === 1 ? 'update' : 'updates'}
                    {:else}
                      All caught up
                    {/if}
                  </p>
                </div>
                <span class={`inline-flex size-8 items-center justify-center rounded-full ${unreadCount > 0 ? 'bg-info/15 text-info' : 'bg-success/15 text-success'}`}>
                  <UMIcon name={unreadCount > 0 ? 'bell' : 'hero-check'} className="size-4" />
                </span>
              </div>

              <div class="border-t border-base-300/60 pt-1">
                {#if unreadCount > 0}
                  <a
                    id="notification-menu-unread"
                    href="/notifications?unread=true"
                    data-phx-link="redirect"
                    data-phx-link-state="push"
                    class="group flex min-h-11 items-center gap-3 rounded-xl px-3 text-sm font-semibold text-base-content/75 transition hover:bg-base-100/70 hover:text-base-content"
                    onclick={closeNotifications}
                  >
                    <span class="inline-flex size-7 items-center justify-center rounded-full bg-info/10 text-info">
                      <UMIcon name="bell" className="size-3.5" />
                    </span>
                    <span class="min-w-0 flex-1">Review unread</span>
                    <span class="badge badge-info badge-sm min-h-5 text-xs font-black">{unreadCount > 99 ? '99+' : unreadCount}</span>
                  </a>
                {:else}
                  <div
                    id="notification-menu-empty"
                    class="flex min-h-11 items-center gap-3 rounded-xl px-3 text-sm font-semibold text-base-content/55"
                  >
                    <span class="inline-flex size-7 items-center justify-center rounded-full bg-success/10 text-success">
                      <UMIcon name="hero-check" className="size-3.5" />
                    </span>
                    <span>Nothing needs attention</span>
                  </div>
                {/if}

                <a
                  id="notification-menu-all"
                  href="/notifications"
                  data-phx-link="redirect"
                  data-phx-link-state="push"
                  class="group mt-1 flex min-h-11 items-center gap-3 rounded-xl px-3 text-sm font-semibold text-base-content/70 transition hover:bg-base-100/70 hover:text-base-content"
                  onclick={closeNotifications}
                >
                  <span class="inline-flex size-7 items-center justify-center rounded-full bg-base-300/70 text-base-content/60">
                    <UMIcon name="hero-inbox" className="size-3.5" />
                  </span>
                  <span class="min-w-0 flex-1">View all notifications</span>
                  <UMIcon name="hero-arrow-right" className="size-4 opacity-40 transition group-hover:translate-x-0.5 group-hover:opacity-75" />
                </a>
              </div>
            </div>
          {/if}
        </div>
      {/if}

      {#if currentUser}
        <div class={showNavLinks ? 'hidden lg:block' : 'block'}>
          <UserMenu {currentUser} />
        </div>
      {:else}
        <div class={showNavLinks ? 'hidden items-center gap-1.5 lg:flex' : 'flex items-center gap-1.5'}>
          <a href="/signin" class="btn btn-ghost btn-sm rounded-full px-4 text-base-content/70">Sign in</a>
          <a href="/signup" class="btn btn-primary btn-sm rounded-full px-5 shadow-sm shadow-primary/15">Sign up</a>
        </div>
      {/if}

      {#if showNavLinks}
      <div
        class="dropdown dropdown-end relative lg:hidden"
        class:dropdown-open={isMenuOpen}
        bind:this={mobileMenuRef}
      >
        <button
          id="mobile-menu-toggle"
          bind:this={mobileTriggerRef}
          onclick={toggleMenu}
          aria-label={isMenuOpen ? 'Close navigation menu' : 'Open navigation menu'}
          aria-expanded={isMenuOpen}
          aria-controls="mobile-nav"
          class={`btn btn-ghost btn-circle size-11 transition ${isMenuOpen ? 'bg-primary/10 text-primary' : 'text-base-content/70'}`}
        >
          <UMIcon name={isMenuOpen ? 'close' : 'bars_3'} className="size-5" />
        </button>

        {#if isMenuOpen}
          <div
            id="mobile-nav"
            class="dropdown-content absolute right-0 top-[calc(100%+0.75rem)] w-[min(21rem,calc(100vw-2rem))] overflow-hidden rounded-2xl bg-base-200 p-2 shadow-xl"
          >
            <p class="px-3 pb-1 pt-2 text-xs font-bold uppercase tracking-[0.14em] text-base-content/45">
              More from UrielM
            </p>
            <ul class="menu gap-1 p-0">
              {#each mobileMoreItems as item}
                <li>
                  <a
                    href={item.href}
                    data-phx-link="redirect"
                    data-phx-link-state="push"
                    data-nav-page={item.page}
                    aria-current={activePage === item.page ? 'page' : undefined}
                    class={`group flex min-h-12 items-center justify-between rounded-xl px-3 text-sm font-bold transition ${mobileLinkClass(item.page)}`}
                    onclick={closeMenu}
                  >
                    {item.label}
                    <UMIcon name="hero-arrow-right" className="size-4 opacity-45 transition group-hover:translate-x-0.5 group-hover:opacity-80" />
                  </a>
                </li>
              {/each}

              {#if currentUser}
                <li class="mt-1 border-t border-base-300/60 pt-1">
                  <a
                    href="/settings"
                    data-phx-link="redirect"
                    data-phx-link-state="push"
                    class="flex min-h-12 items-center gap-3 rounded-xl px-3 text-sm font-semibold text-base-content/70 transition hover:bg-base-200 hover:text-base-content"
                    onclick={closeMenu}
                  >
                    <UMIcon name="hero-cog-6-tooth" className="size-4" />
                    Settings
                  </a>
                </li>
              {/if}
            </ul>

            {#if !currentUser}
              <div class="grid grid-cols-2 gap-2 p-2 pt-3">
                <a href="/signin" class="btn btn-ghost min-h-11 rounded-full" onclick={closeMenu}>Sign in</a>
                <a href="/signup" class="btn btn-primary min-h-11 rounded-full" onclick={closeMenu}>Sign up</a>
              </div>
            {/if}
          </div>
        {/if}
      </div>
      {/if}
    </div>
  </nav>
</header>
