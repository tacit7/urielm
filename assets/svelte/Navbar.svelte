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

<nav
  class={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
    isScrolled ? 'bg-white/80 backdrop-blur-md border-b border-gray-100 py-4' : 'bg-transparent py-6'
  }`}
>
  <div class="max-w-7xl mx-auto px-6 flex justify-between items-center">
    <div class="text-2xl font-semibold tracking-tight text-gray-900 flex items-center gap-2">
      urielm<span class="text-gray-400">.dev</span>
    </div>

    <!-- Desktop Menu -->
    <div class="hidden md:flex space-x-8 text-sm font-medium text-gray-500">
      <a href="#content" class="hover:text-gray-900 transition-colors">Content</a>
      <a href="#automation" class="hover:text-gray-900 transition-colors">Automation</a>
      <a href="#consulting" class="hover:text-gray-900 transition-colors">Consulting</a>
    </div>

    <div class="hidden md:block">
      <button class="bg-black text-white px-5 py-2 rounded-full text-sm font-medium hover:bg-gray-800 transition-all transform hover:scale-105 active:scale-95 shadow-lg shadow-gray-200">
        Get in Touch
      </button>
    </div>

    <!-- Mobile Toggle -->
    <button
      class="md:hidden text-gray-900"
      onclick={toggleMobileMenu}
    >
      {#if mobileMenuOpen}
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <line x1="18" y1="6" x2="6" y2="18"></line>
          <line x1="6" y1="6" x2="18" y2="18"></line>
        </svg>
      {:else}
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <line x1="3" y1="12" x2="21" y2="12"></line>
          <line x1="3" y1="6" x2="21" y2="6"></line>
          <line x1="3" y1="18" x2="21" y2="18"></line>
        </svg>
      {/if}
    </button>
  </div>

  <!-- Mobile Menu -->
  {#if mobileMenuOpen}
    <div class="absolute top-full left-0 right-0 bg-white border-b border-gray-100 p-6 md:hidden flex flex-col space-y-4 shadow-xl">
      <a href="#content" class="text-lg font-medium text-gray-900">Content</a>
      <a href="#automation" class="text-lg font-medium text-gray-900">Automation</a>
      <a href="#consulting" class="text-lg font-medium text-gray-900">Consulting</a>
      <button class="bg-black text-white px-5 py-3 rounded-full text-sm font-medium w-full mt-4">
        Get in Touch
      </button>
    </div>
  {/if}
</nav>
