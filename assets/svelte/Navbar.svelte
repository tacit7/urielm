<script>
  import { onMount, onDestroy } from 'svelte';
  import ThemeSelector from './ThemeSelector.svelte';

  export let currentPage = '';

  let isScrolled = false;
  let isMenuOpen = false;
  let dropdownRef;

  function handleScroll() {
    isScrolled = window.scrollY > 20;
  }

  function toggleMenu() {
    isMenuOpen = !isMenuOpen;
  }

  function closeMenu() {
    isMenuOpen = false;
  }

  function handleClickOutside(event) {
    if (dropdownRef && !dropdownRef.contains(event.target)) {
      closeMenu();
    }
  }

  onMount(() => {
    handleScroll(); // Set initial state
    window.addEventListener('scroll', handleScroll);
    document.addEventListener('click', handleClickOutside);
  });

  onDestroy(() => {
    window.removeEventListener('scroll', handleScroll);
    document.removeEventListener('click', handleClickOutside);
  });
</script>

<div
  class={`navbar fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
    isScrolled ? 'bg-base-100/80 backdrop-blur-md border-b border-base-300' : 'bg-transparent'
  }`}
>
  <div class="navbar-start">
    <!-- Mobile Dropdown -->
    <div class="dropdown lg:hidden" class:dropdown-open={isMenuOpen} bind:this={dropdownRef}>
      <button
        on:click={toggleMenu}
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
          <li><a href="/" class:active={currentPage === 'home'} on:click={closeMenu}>Home</a></li>
          <li><a href="/references?category=coding" on:click={closeMenu}>Coding</a></li>
          <li><a href="/references?category=ai" on:click={closeMenu}>AI</a></li>
          <li><a href="/references?category=n8n" on:click={closeMenu}>n8n</a></li>
          <li><a href="/references?category=tools" on:click={closeMenu}>Tools</a></li>
          <li><a href="/references" class:active={currentPage === 'references'} on:click={closeMenu}>Prompts</a></li>
        </ul>
      {/if}
    </div>

    <!-- Logo -->
    <a href="/" class="btn btn-ghost text-xl font-semibold tracking-tight">
      UrielM<span class="text-base-content/50">.dev</span>
    </a>
  </div>

  <!-- Desktop Navigation - Center -->
  <div class="navbar-center hidden lg:flex">
    <div class="flex items-center gap-8">
      <a
        href="/"
        class={`font-medium transition-colors ${currentPage === 'home' ? 'text-primary font-bold' : 'text-base-content hover:text-primary'}`}
      >
        Home
      </a>
      <a
        href="/references?category=coding"
        class="font-medium text-base-content hover:text-primary transition-colors"
      >
        Coding
      </a>
      <a
        href="/references?category=ai"
        class="font-medium text-base-content hover:text-primary transition-colors"
      >
        AI
      </a>
      <a
        href="/references?category=n8n"
        class="font-medium text-base-content hover:text-primary transition-colors"
      >
        n8n
      </a>
      <a
        href="/references?category=tools"
        class="font-medium text-base-content hover:text-primary transition-colors"
      >
        Tools
      </a>
      <a
        href="/references"
        class={`font-medium transition-colors ${currentPage === 'references' ? 'text-primary font-bold' : 'text-base-content hover:text-primary'}`}
      >
        Prompts
      </a>
    </div>
  </div>

  <!-- CTA Button - Right -->
  <div class="navbar-end gap-2">
    <ThemeSelector />
    <a
      href="mailto:hello@urielm.dev"
      class="btn btn-sm btn-primary rounded-full px-6"
    >
      Get in Touch
    </a>
  </div>
</div>
