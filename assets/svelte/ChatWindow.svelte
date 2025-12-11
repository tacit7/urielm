<script>
  import { onMount } from "svelte"
  import { Socket } from "phoenix"

  export let room
  export let messages = []
  export let userId

  let newMessage = ""
  let channel = null
  let socket = null
  let isConnected = false
  let messageList = null
  let hoveredMessageId = null

  onMount(async () => {
    socket = new Socket("/socket", {
      params: { user_id: userId }
    })
    socket.connect()

    channel = socket.channel(`room:${room.id}`)

    channel.on("message_created", (payload) => {
      messages = [...messages, payload]
      scrollToBottom()
    })

    channel.on("typing", (payload) => {
      console.log(`${payload.username} is typing...`)
    })

    channel
      .join()
      .receive("ok", (resp) => {
        if (resp.messages) {
          messages = resp.messages
        }
        isConnected = true
        scrollToBottom()
      })
      .receive("error", (resp) => {
        console.error("Unable to join", resp)
        isConnected = false
      })

    return () => {
      if (channel) channel.leave()
      if (socket) socket.disconnect()
    }
  })

  function sendMessage() {
    if (!newMessage.trim() || !isConnected) return
    channel.push("new_message", { body: newMessage.trim() })
    newMessage = ""
  }

  function scrollToBottom() {
    setTimeout(() => {
      if (messageList) {
        messageList.scrollTop = messageList.scrollHeight
      }
    }, 100)
  }

  function handleTyping() {
    if (channel) {
      channel.push("typing", {})
    }
  }

  function formatTime(timestamp) {
    const date = new Date(timestamp)
    return date.toLocaleTimeString("en-US", {
      hour: "numeric",
      minute: "2-digit",
      hour12: true
    })
  }
</script>

<div class="chat-wrapper bg-base-100 flex flex-col h-full">
  <!-- Header -->
  <div class="chat-header bg-base-100 border-b border-base-300 px-6 py-4 flex items-center justify-between">
    <div>
      <h2 class="text-xl font-bold text-base-content"># {room.name}</h2>
      {#if room.description}
        <p class="text-sm text-base-content/70 mt-1">{room.description}</p>
      {/if}
    </div>
    <div class="badge" class:badge-success={isConnected} class:badge-error={!isConnected}>
      <span class="inline-block w-2 h-2 rounded-full mr-2" class:bg-success={isConnected} class:bg-error={!isConnected} />
      {isConnected ? "Online" : "Offline"}
    </div>
  </div>

  <!-- Messages -->
  <div bind:this={messageList} class="messages-container flex-1 overflow-y-auto px-6 py-4 space-y-2 bg-base-100">
    {#if messages.length === 0}
      <div class="flex flex-col items-center justify-center h-full gap-3 text-base-content/50">
        <div class="text-5xl opacity-60">💬</div>
        <p class="text-lg font-semibold text-base-content">Welcome to #{room.name}</p>
        <p class="text-sm">Start the conversation</p>
      </div>
    {:else}
      {#each messages as msg (msg.id)}
        <div
          class="message-group hover:bg-base-200 rounded p-2 transition-colors duration-150"
          on:mouseenter={() => (hoveredMessageId = msg.id)}
          on:mouseleave={() => (hoveredMessageId = null)}
        >
          <div class="flex gap-3">
            <div class="avatar flex-shrink-0">
              <div class="w-10 h-10 rounded-full bg-gradient-to-br from-primary to-secondary flex items-center justify-center text-primary-content font-bold text-sm shadow-lg">
                {(msg.username || "?").charAt(0).toUpperCase()}
              </div>
            </div>
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2">
                <span class="font-semibold text-base-content text-sm">{msg.username || "Unknown"}</span>
                <span class="text-xs text-base-content/50 opacity-0 transition-opacity" class:opacity-100={hoveredMessageId === msg.id}>
                  {formatTime(msg.inserted_at)}
                </span>
              </div>
              <p class="text-base-content/80 text-sm mt-1 break-words leading-relaxed">{msg.body}</p>
            </div>
          </div>
        </div>
      {/each}
    {/if}
  </div>

  <!-- Input Area -->
  <div class="input-section bg-base-100 border-t border-base-300 px-6 py-4">
    <div class="flex gap-2 items-center">
      <input
        type="text"
        bind:value={newMessage}
        on:keydown={(e) => e.key === "Enter" && sendMessage()}
        on:input={handleTyping}
        placeholder="Message #{room.name}"
        disabled={!isConnected}
        autocomplete="off"
        class="input input-bordered input-sm flex-1 bg-base-200 border-base-300 text-base-content placeholder-base-content/50 focus:outline-none focus:border-primary"
      />
      <button
        on:click={sendMessage}
        disabled={!isConnected || !newMessage.trim()}
        class="btn btn-primary btn-sm btn-circle"
        aria-label="Send message"
      >
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <line x1="22" y1="2" x2="11" y2="13" />
          <polygon points="22 2 15 22 11 13 2 9 22 2" />
        </svg>
      </button>
    </div>
  </div>
</div>

<style>
  :global {
    @import url("https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap");
  }

  .chat-wrapper {
    font-family: "Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  }

  .messages-container {
    scroll-behavior: smooth;
  }

  .messages-container::-webkit-scrollbar {
    width: 8px;
  }

  .messages-container::-webkit-scrollbar-track {
    background: transparent;
  }

  .messages-container::-webkit-scrollbar-thumb {
    @apply bg-base-700 rounded;
  }

  .messages-container::-webkit-scrollbar-thumb:hover {
    @apply bg-base-600;
  }
</style>
