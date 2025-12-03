<script>
  import { onMount, onDestroy } from 'svelte';

  let isScrolled = $state(false);
  let mobileMenuOpen = $state(false);

  function handleScroll() {
    isScrolled = window.scrollY > 20;
  }

  function toggleMobileMenu() {
    mobileMenuOpen = !mobileMenuOpen;
  }

  onMount(() => {
    window.addEventListener('scroll', handleScroll);
  });

  onDestroy(() => {
    window.removeEventListener('scroll', handleScroll);
  });
</script>

<div
  class={`navbar fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
    isScrolled ? 'bg-base-100/80 backdrop-blur-md border-b border-base-300' : 'bg-transparent'
  }`}
>
  <div class="navbar-start">
    <div class="dropdown md:hidden">
      <button
        tabindex="0"
        class="btn btn-ghost"
        onclick={toggleMobileMenu}
      >
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
        </svg>
      </button>
      {#if mobileMenuOpen}
        <ul tabindex="0" class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 rounded-box w-52">
          <li><a href="#content">Content</a></li>
          <li><a href="#automation">Automation</a></li>
          <li><a href="#consulting">Consulting</a></li>
          <li class="mt-2">
            <button class="btn btn-primary btn-sm w-full">Get in Touch</button>
          </li>
        </ul>
      {/if}
    </div>
    <a href="/" class="btn btn-ghost text-xl font-semibold tracking-tight">
      urielm<span class="text-base-content/50">.dev</span>
    </a>
  </div>

  <div class="navbar-center hidden md:flex">
    <ul class="menu menu-horizontal px-1">
      <li><a href="#content">Content</a></li>
      <li><a href="#automation">Automation</a></li>
      <li><a href="#consulting">Consulting</a></li>
    </ul>
  </div>

  <div class="navbar-end">
    <button class="btn btn-primary btn-sm">Get in Touch</button>
  </div>
</div>
