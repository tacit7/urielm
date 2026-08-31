import test from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"

const navbar = readFileSync(new URL("./Navbar.svelte", import.meta.url), "utf8")
const userMenu = readFileSync(new URL("./UserMenu.svelte", import.meta.url), "utf8")

function classForId(source, id) {
  return source.match(new RegExp(`id="${id}"[\\s\\S]*?class="([^"]+)"`))?.[1] || ""
}

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

test("theme control lives in the account menu", () => {
  assert.doesNotMatch(navbar, /ThemeToggle/)
  assert.doesNotMatch(navbar, /mobile-theme-control/)
  assert.match(userMenu, /<UMIcon name=\{themeEnabled \? 'hero-moon' : 'hero-sun'\} className="size-4" \/>/)
  assert.match(userMenu, />\s*Theme\s*<\/button>/)
})

test("account menu uses the shared icon system and controlled state", () => {
  assert.doesNotMatch(userMenu, /lucide-svelte/)
  assert.match(userMenu, /<UMIcon/)
  assert.match(userMenu, /aria-expanded=\{isMenuOpen\}/)
  assert.match(userMenu, /aria-controls="account-menu"/)
  assert.match(userMenu, /id="account-menu"/)
})

test("account menu trigger uses a compact custom avatar treatment", () => {
  assert.match(userMenu, /id="account-menu-toggle"[\s\S]*?class=\{`[\s\S]*?size-10/)
  assert.match(userMenu, /size-8 items-center justify-center rounded-full bg-base-300\/75/)
  assert.doesNotMatch(userMenu, /avatar placeholder/)
})

test("notification menu exposes compact unread and empty states", () => {
  assert.match(navbar, /aria-expanded=\{isNotificationsOpen\}/)
  assert.match(navbar, /aria-controls="notification-menu"/)
  assert.match(navbar, /id="notification-menu"/)
  assert.match(navbar, /id="notification-menu-unread"/)
  assert.match(navbar, /id="notification-menu-empty"/)
  assert.match(navbar, /id="notification-menu-all"/)
})

test("navigation dropdowns use a distinct elevated surface", () => {
  assert.match(classForId(navbar, "mobile-nav"), /bg-base-200/)
  assert.match(classForId(navbar, "notification-menu"), /bg-base-200/)
  assert.match(classForId(userMenu, "account-menu"), /bg-base-200/)
  assert.doesNotMatch(classForId(navbar, "mobile-nav"), /bg-base-100/)
  assert.doesNotMatch(classForId(userMenu, "account-menu"), /bg-base-100/)
})
