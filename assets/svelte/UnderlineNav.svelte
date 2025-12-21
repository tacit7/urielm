<script>
  /**
   * GitHub-style underline navigation component
   *
   * @param {Array} items - Array of tab objects: [{ key: string, label: string, icon?: string, count?: number }]
   * @param {string} activeKey - Currently active tab key
   * @param {Function} onTabChange - Callback when tab is clicked: (key: string) => void
   * @param {boolean} showCounts - Whether to show count badges (default: true)
   * @param {string} size - Size variant: 'sm' | 'md' | 'lg' (default: 'md')
   */
  let {
    items = [],
    activeKey = '',
    onTabChange = () => {},
    showCounts = true,
    size = 'md',
    live
  } = $props()

  const sizeClasses = {
    sm: 'px-3 py-1.5 text-xs',
    md: 'px-4 py-2 text-sm',
    lg: 'px-5 py-3 text-base'
  }

  function handleTabClick(key, event) {
    // For anchor-style keys (section names), just let browser handle it
    // LiveView event is sent for tracking active state only
    if (live) {
      live.pushEvent('tab_change', { key })
    } else {
      onTabChange(key)
    }
  }
</script>

<div class="border-b border-base-300">
  <div class="px-6">
    <div role="tablist" class="flex items-center gap-1 -mb-px overflow-x-auto scrollbar-hide">
      {#each items as item}
        <button
          type="button"
          role="tab"
          id={`tab-${item.key}`}
          aria-selected={activeKey === item.key}
          aria-controls={`panel-${item.key}`}
          class="flex items-center gap-2 border-b-2 transition-colors whitespace-nowrap
                 {sizeClasses[size]}
                 {activeKey === item.key
                   ? 'border-primary font-medium text-base-content'
                   : 'border-transparent text-base-content/60 hover:text-base-content hover:border-base-content/20'}"
          onclick={(e) => handleTabClick(item.key, e)}
        >
          {#if item.icon}
            <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 16 16">
              <path d={item.icon} />
            </svg>
          {/if}

          <span>{item.label}</span>

          {#if showCounts && item.count !== undefined && item.count > 0}
            <span class="badge badge-sm badge-ghost">
              {item.count}
            </span>
          {/if}
        </button>
      {/each}
    </div>
  </div>
</div>

<style>
  /* Hide scrollbar but keep functionality */
  .scrollbar-hide {
    -ms-overflow-style: none;
    scrollbar-width: none;
  }
  .scrollbar-hide::-webkit-scrollbar {
    display: none;
  }
</style>
