<script>
  import { onMount } from "svelte"
  import { Socket } from "phoenix"
  import { fly } from "svelte/transition"

  export let room
  export let messages = []
  export let userId

  let newMessage = ""
  let channel = null
  let socket = null
  let isConnected = false
  let messageList = null
  let textareaElement = null

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
    if (textareaElement) {
      textareaElement.style.height = "auto"
    }
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

  function handleInput(e) {
    const target = e.target
    target.style.height = "auto"
    target.style.height = Math.min(target.scrollHeight, 120) + "px"
    handleTyping()
  }

  function formatTime(timestamp) {
    const date = new Date(timestamp)
    return date.toLocaleTimeString("en-US", {
      hour: "numeric",
      minute: "2-digit",
      hour12: true
    })
  }

  function isMessageSequence(index) {
    return index > 0 && messages[index - 1].user_id === messages[index].user_id
  }

  function isCurrentUser(userId) {
    return userId === parseInt(userId)
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
  <div bind:this={messageList} class="messages-container flex-1 overflow-y-auto px-4 py-4 bg-base-100">
    {#if messages.length === 0}
      <div class="flex flex-col items-center justify-center h-full gap-3 text-base-content/50">
        <div class="text-5xl opacity-60">💬</div>
        <p class="text-lg font-semibold text-base-content">Welcome to #{room.name}</p>
        <p class="text-sm">Start the conversation</p>
      </div>
    {:else}
      {#each messages as msg, i (msg.id)}
        {@const isSequence = isMessageSequence(i)}
        {@const isMine = msg.user_id.toString() === userId}

        <div class="chat {isMine ? 'chat-end' : 'chat-start'} {isSequence ? 'mt-1' : 'mt-4'}" in:fly={{ y: 20, duration: 300 }}>
          {#if !isSequence}
            <div class="chat-image avatar">
              <div class="w-8 h-8 rounded-full bg-gradient-to-br from-primary to-secondary flex items-center justify-center text-primary-content font-bold text-xs shadow-md">
                {(msg.username || "?").charAt(0).toUpperCase()}
              </div>
            </div>
            <div class="chat-header text-xs text-base-content/60 mb-1">
              {msg.username || "Unknown"}
              <time class="text-[10px] text-base-content/40 ml-2">{formatTime(msg.inserted_at)}</time>
            </div>
          {/if}

          <div class="chat-bubble {isMine ? 'bg-primary text-primary-content' : 'bg-base-200 text-base-content'} max-w-xs break-words">
            {msg.body}
          </div>
        </div>
      {/each}
    {/if}
  </div>

  <!-- Input Area -->
  <div class="input-section bg-base-100 border-t border-base-300 px-4 py-3">
    <div class="flex gap-2 items-end rounded-3xl bg-base-200 px-4 py-2">
      <textarea
        bind:this={textareaElement}
        bind:value={newMessage}
        on:keydown={(e) => {
          if (e.key === "Enter" && !e.shiftKey) {
            e.preventDefault()
            sendMessage()
          }
        }}
        on:input={handleInput}
        placeholder="Message #{room.name}"
        disabled={!isConnected}
        autocomplete="off"
        rows="1"
        class="textarea textarea-bordered-0 flex-1 bg-base-200 text-base-content placeholder-base-content/50 focus:outline-none resize-none max-h-[120px] p-0 border-0"
      />
      <button
        on:click={sendMessage}
        disabled={!isConnected || !newMessage.trim()}
        class="btn btn-primary btn-sm btn-circle flex-shrink-0"
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
