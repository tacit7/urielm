<script>
  export let activeFilter = 'all';
  export let categories = [];
  export let live;

  function selectFilter(filter) {
    live.pushEvent('filter_changed', {category: filter});
  }
</script>

<div class="border-b border-gray-200 dark:border-white/10 bg-white dark:bg-[#0f0f0f]">
  <div class="container mx-auto px-4">
    <nav class="flex gap-6 overflow-x-auto scrollbar-hide" aria-label="Reference filters">
      <button
        on:click={() => selectFilter('all')}
        class={`py-3 px-1 border-b-2 font-medium text-sm transition-colors whitespace-nowrap ${
          activeFilter === 'all'
            ? 'border-purple-600 text-purple-600 dark:text-purple-400'
            : 'border-transparent text-gray-600 dark:text-white/60 hover:text-gray-900 dark:hover:text-white hover:border-gray-300 dark:hover:border-white/30'
        }`}
      >
        All
      </button>
      {#each categories as category}
        <button
          on:click={() => selectFilter(category)}
          class={`py-3 px-1 border-b-2 font-medium text-sm transition-colors whitespace-nowrap capitalize ${
            activeFilter === category
              ? 'border-purple-600 text-purple-600 dark:text-purple-400'
              : 'border-transparent text-gray-600 dark:text-white/60 hover:text-gray-900 dark:hover:text-white hover:border-gray-300 dark:hover:border-white/30'
          }`}
        >
          {category}
        </button>
      {/each}
    </nav>
  </div>
</div>
