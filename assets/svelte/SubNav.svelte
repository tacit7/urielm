<script>
  let { activeFilter = 'all', categories = [], live } = $props()

  function selectFilter(filter) {
    live.pushEvent('filter_changed', { category: filter })
  }
</script>

<div class="bg-base-100 border-b border-base-300">
  <div class="container mx-auto px-4">
    <div class="tabs tabs-bordered overflow-x-auto scrollbar-hide" aria-label="Reference filters" role="tablist">
      <button
        type="button"
        onclick={() => selectFilter('all')}
        role="tab"
        aria-selected={activeFilter === 'all'}
        class={`tab tab-sm sm:tab-md whitespace-nowrap transition-colors duration-200 hover:text-primary ${activeFilter === 'all' ? 'tab-active' : ''}`}
      >
        All
      </button>
      {#each categories as category}
        <button
          type="button"
          onclick={() => selectFilter(category)}
          role="tab"
          aria-selected={activeFilter === category}
          class={`tab tab-sm sm:tab-md whitespace-nowrap capitalize transition-colors duration-200 hover:text-primary ${activeFilter === category ? 'tab-active' : ''}`}
        >
          {category}
        </button>
      {/each}
    </div>
  </div>
  
</div>
