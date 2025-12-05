<script>
  let { count = 0, live } = $props()

  function increment() {
    live.pushEvent('increment', {})
  }

  function decrement() {
    live.pushEvent('decrement', {})
  }
</script>

<div class="flex flex-col items-center gap-4 p-8">
  <h2 class="text-3xl font-bold">Counter: {count}</h2>

  <div class="flex gap-2">
    <button
      onclick={decrement}
      class="btn btn-error"
    >
      Decrement
    </button>

    <button
      onclick={increment}
      class="btn btn-primary"
    >
      Increment
    </button>
  </div>
</div>
