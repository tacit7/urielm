import test from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"

const navbar = readFileSync(new URL("./Navbar.svelte", import.meta.url), "utf8")
const themeToggle = readFileSync(new URL("./ThemeToggle.svelte", import.meta.url), "utf8")
const userMenu = readFileSync(new URL("./UserMenu.svelte", import.meta.url), "utf8")

test("mobile navigation exposes controlled menu semantics", () => {
  assert.match(navbar, /aria-expanded=\{isMenuOpen\}/)
  assert.match(navbar, /aria-controls="mobile-nav"/)
  assert.match(navbar, /mobileMoreItems/)
  assert.match(navbar, /class="menu/)
  assert.match(navbar, /class="dropdown dropdown-end relative lg:hidden"/)
})

test("desktop navigation uses the daisyUI horizontal menu structure", () => {
  assert.match(navbar, /class="navbar-center[^\"]*absolute[^\"]*left-1\/2[^\"]*-translate-x-1\/2[^\"]*lg:flex"/)
  assert.match(navbar, /<ul id="desktop-nav-links" class="menu menu-horizontal/)
  assert.match(navbar, /\{#each primaryNavItems as item\}\s*<li>/)
})

test("theme control swaps aligned sun and moon icons", () => {
  assert.match(themeToggle, /class:swap-active=\{currentTheme === DARK_THEME\}/)
  assert.match(themeToggle, /class="[^"]*swap swap-rotate[^"]*size-11[^"]*"/)
  assert.match(themeToggle, /<UMIcon name="sun" className="swap-on size-4" \/>/)
  assert.match(themeToggle, /<UMIcon name="moon" className="swap-off size-4" \/>/)
})

test("account menu uses the shared icon system and controlled state", () => {
  assert.doesNotMatch(userMenu, /lucide-svelte/)
  assert.match(userMenu, /<UMIcon/)
  assert.match(userMenu, /aria-expanded=\{isMenuOpen\}/)
  assert.match(userMenu, /aria-controls="account-menu"/)
  assert.match(userMenu, /id="account-menu"/)
})

test("navigation dropdowns use a distinct elevated surface", () => {
  assert.match(navbar, /id="mobile-nav"[\s\S]*?bg-base-200/)
  assert.match(userMenu, /id="account-menu"[\s\S]*?bg-base-200/)
  assert.doesNotMatch(navbar, /id="mobile-nav"[\s\S]*?bg-base-100/)
  assert.doesNotMatch(userMenu, /id="account-menu"[\s\S]*?bg-base-100/)
})
