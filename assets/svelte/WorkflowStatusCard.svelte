<script>
  let { delay = 0 } = $props()
</script>

<div
  class="absolute hidden lg:block bottom-20 right-10 xl:right-32 w-auto bg-base-100/40 backdrop-blur-xl border border-base-300/50 shadow-[0_20px_40px_-15px_rgba(0,0,0,0.1)] rounded-2xl p-4 animate-float rotate-[3deg]"
  style="animation-delay: {delay}s"
>
  <div class="flex items-center space-x-3 pr-2">
    <div class="w-10 h-10 rounded-xl bg-[#EA4B71] flex items-center justify-center text-white shadow-lg shadow-pink-500/20">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-5 h-5">
        <path fill-rule="evenodd" d="M15.312 11.424a5.5 5.5 0 01-9.201 2.466l-.312-.311h2.433a.75.75 0 000-1.5H3.989a.75.75 0 00-.75.75v4.242a.75.75 0 001.5 0v-2.43l.31.31a7 7 0 0011.712-3.138.75.75 0 00-1.449-.39zm1.23-3.723a.75.75 0 00.219-.53V2.929a.75.75 0 00-1.5 0V5.36l-.31-.31A7 7 0 003.239 8.188a.75.75 0 101.448.389A5.5 5.5 0 0113.89 6.11l.311.31h-2.432a.75.75 0 000 1.5h4.243a.75.75 0 00.53-.219z" clip-rule="evenodd" />
      </svg>
    </div>
    <div class="text-left">
      <div class="text-xs text-base-content/60 font-medium">Active Workflow</div>
      <div class="text-sm font-bold text-base-content">Lead Gen Bot · Running</div>
    </div>
  </div>
</div>
