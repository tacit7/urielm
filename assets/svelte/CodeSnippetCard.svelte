<script>
  export let delay = 0;
</script>

<div
  class="absolute hidden lg:block top-1/4 left-10 xl:left-32 w-64 bg-base-200/90 backdrop-blur-xl border border-base-300 shadow-[0_20px_40px_-15px_rgba(0,0,0,0.1)] rounded-2xl p-4 animate-float rotate-[-3deg]"
  style="animation-delay: {delay}s"
>
  <div class="font-mono text-[10px] text-base-content/70 leading-relaxed">
    <div class="flex gap-2 mb-2 border-b border-base-300 pb-2">
      <div class="w-2 h-2 rounded-full bg-red-500"></div>
      <div class="w-2 h-2 rounded-full bg-yellow-500"></div>
      <div class="w-2 h-2 rounded-full bg-green-500"></div>
    </div>
    <div class="text-blue-400">
      const <span class="text-yellow-200">automate</span> = <span class="text-purple-400">async</span> () => {'{'}
    </div>
    <div class="pl-4">
      await <span class="text-green-300">n8n</span>.trigger();
    </div>
    <div class="pl-4">
      return <span class="text-orange-300">"Freedom"</span>;
    </div>
    <div>{'}'}</div>
  </div>
</div>
