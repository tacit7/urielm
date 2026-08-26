import test from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"

const navbar = readFileSync(new URL("./Navbar.svelte", import.meta.url), "utf8")
const userMenu = readFileSync(new URL("./UserMenu.svelte", import.meta.url), "utf8")

test("mobile navigation exposes controlled menu semantics", () => {
  assert.match(navbar, /aria-expanded=\{isMenuOpen\}/)
  assert.match(navbar, /aria-controls="mobile-nav"/)
  assert.match(navbar, /mobileMoreItems/)
  assert.match(navbar, /class="menu/)
  assert.match(navbar, /class="dropdown dropdown-end relative lg:hidden"/)
})

test("desktop navigation uses the daisyUI horizontal menu structure", () => {
  assert.match(navbar, /<ul id="desktop-nav-links" class="menu menu-horizontal/)
  assert.match(navbar, /\{#each primaryNavItems as item\}\s*<li>/)
})

test("account menu uses the shared icon system and controlled state", () => {
  assert.doesNotMatch(userMenu, /lucide-svelte/)
  assert.match(userMenu, /<UMIcon/)
  assert.match(userMenu, /aria-expanded=\{isMenuOpen\}/)
  assert.match(userMenu, /aria-controls="account-menu"/)
  assert.match(userMenu, /id="account-menu"/)
})
