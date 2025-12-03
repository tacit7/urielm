<script>
  export let count = 0
  export let live

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
      on:click={decrement}
      class="px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600 transition"
    >
      Decrement
    </button>

    <button
      on:click={increment}
      class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 transition"
    >
      Increment
    </button>
  </div>
</div>
