// Theme management: keep theme in sync with localStorage and custom events
(() => {
  const setCookie = (name, value, options = {}) => {
    const opts = {path: '/', 'max-age': 60*60*24*365, ...options}
    let cookie = encodeURIComponent(name) + '=' + encodeURIComponent(value)
    if (opts['max-age'] == 0) {
      cookie += ' ; Max-Age=0'
    } else {
      cookie += ' ; Max-Age=' + opts['max-age']
    }
    if (opts.path) cookie += ' ; Path=' + opts.path
    document.cookie = cookie
  }

  const setTheme = (theme) => {
    if (theme === "system") {
      try { localStorage.removeItem("phx:theme") } catch (_) {}
      try { setCookie('phx_theme', '', {'max-age': 0}) } catch (_) {}
      document.documentElement.removeAttribute("data-theme")
    } else {
      try { localStorage.setItem("phx:theme", theme) } catch (_) {}
      try { setCookie('phx_theme', theme) } catch (_) {}
      document.documentElement.setAttribute("data-theme", theme)
    }
  }
  if (!document.documentElement.hasAttribute("data-theme")) {
    try {
      let savedTheme = localStorage.getItem("phx:theme") || "system"
      // Migrate old themes to 'midnight'
      if (savedTheme === "dark" || savedTheme === "tokyo-night") {
        savedTheme = "midnight"
        localStorage.setItem("phx:theme", "midnight")
      }
      setTheme(savedTheme)
    } catch (_) {
      setTheme("system")
    }
  }
  window.addEventListener("storage", (e) => e.key === "phx:theme" && setTheme(e.newValue || "system"))
  window.addEventListener("phx:set-theme", (e) => setTheme(e.detail?.theme ?? e.target?.dataset?.phxTheme ?? "system"))
})()

// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {getHooks} from "live_svelte"
import topbar from "../vendor/topbar"
import hljs from "highlight.js"

// Expose hljs globally for syntax highlighting in templates
window.hljs = hljs

// Import Svelte components
import Counter from "../svelte/Counter.svelte"
import Navbar from "../svelte/Navbar.svelte"
import CodeSnippetCard from "../svelte/CodeSnippetCard.svelte"
import ThemeToggle from "../svelte/ThemeToggle.svelte"
import ThemeSelector from "../svelte/ThemeSelector.svelte"
import SubNav from "../svelte/SubNav.svelte"
import AuthModal from "../svelte/AuthModal.svelte"
import UserMenu from "../svelte/UserMenu.svelte"
import GoogleSignInButton from "../svelte/GoogleSignInButton.svelte"
import YouTubePlayer from "../svelte/lib/youtube/YouTubePlayer.svelte"
import ChatWindow from "../svelte/ChatWindow.svelte"
import MarkdownRenderer from "../svelte/MarkdownRenderer.svelte"
import PromptActions from "../svelte/PromptActions.svelte"
import ThreadCard from "../svelte/ThreadCard.svelte"
import VoteButtons from "../svelte/VoteButtons.svelte"
import CommentTree from "../svelte/CommentTree.svelte"
import PostActions from "../svelte/PostActions.svelte"
import MarkdownInput from "../svelte/MarkdownInput.svelte"

// Infinite scroll hook
const InfiniteScroll = {
  mounted() {
    this.observer = new IntersectionObserver(
      (entries) => {
        const entry = entries[0]
        if (entry.isIntersecting) {
          this.pushEvent("load_more", {})
        }
      },
      {
        root: null,
        rootMargin: "100px",
        threshold: 0.1
      }
    )
    this.observer.observe(this.el)
  },
  destroyed() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }
}

// Copy to clipboard hook
const CopyToClipboard = {
  mounted() {
    this.el.addEventListener("click", () => {
      const text = this.el.dataset.text || this.el.textContent
      navigator.clipboard.writeText(text).then(
        () => {
          // Visual feedback - change button text briefly
          const originalText = this.el.textContent
          this.el.textContent = "✓ Copied!"
          setTimeout(() => {
            this.el.textContent = originalText
          }, 2000)
        },
        (err) => {
          console.error("Failed to copy:", err)
        }
      )
    })
  }
}

// Close modal hook
window.addEventListener("phx:close_modal", (e) => {
  const modalId = e.detail.id
  const modal = document.getElementById(modalId)
  if (modal && modal.tagName === "DIALOG") {
    modal.classList.remove("modal-open")
    modal.close()
  }
})

// Toast notification handler
window.addEventListener("show-toast", (e) => {
  const {message, type = 'info'} = e.detail
  // For now, just log to console. Can be enhanced with a toast UI component later
  console.log(`[${type.toUpperCase()}] ${message}`)
})

// Register Svelte components as LiveView hooks
let Hooks = getHooks({
  Counter,
  Navbar,
  CodeSnippetCard,
  ThemeToggle,
  ThemeSelector,
  SubNav,
  AuthModal,
  UserMenu,
  GoogleSignInButton,
  YouTubePlayer,
  ChatWindow,
  MarkdownRenderer,
  PromptActions,
  ThreadCard,
  VoteButtons,
  CommentTree,
  PostActions,
  MarkdownInput
})

// Add custom hooks
Hooks.InfiniteScroll = InfiniteScroll
Hooks.CopyToClipboard = CopyToClipboard

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks,
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}
