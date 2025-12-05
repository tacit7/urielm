<script>
  export let activeFilter = 'all';
  export let categories = [];
  export let live;

  function selectFilter(filter) {
    live.pushEvent('filter_changed', {category: filter});
  }
</script>

<div class="border-b border-base-300 bg-base-100">
  <div class="container mx-auto px-4">
    <nav class="flex gap-6 overflow-x-auto scrollbar-hide" aria-label="Reference filters">
      <button
        on:click={() => selectFilter('all')}
        class={`py-3 px-1 border-b-2 font-medium text-sm transition-colors whitespace-nowrap ${
          activeFilter === 'all'
            ? 'border-primary text-primary'
            : 'border-transparent text-base-content/60 hover:text-base-content hover:border-base-300'
        }`}
      >
        All
      </button>
      {#each categories as category}
        <button
          on:click={() => selectFilter(category)}
          class={`py-3 px-1 border-b-2 font-medium text-sm transition-colors whitespace-nowrap capitalize ${
            activeFilter === category
              ? 'border-primary text-primary'
              : 'border-transparent text-base-content/60 hover:text-base-content hover:border-base-300'
          }`}
        >
          {category}
        </button>
      {/each}
    </nav>
  </div>
</div>
