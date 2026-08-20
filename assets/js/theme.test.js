import test from "node:test"
import assert from "node:assert/strict"
import {DARK_THEME, LIGHT_THEME, normalizeTheme, oppositeTheme} from "./theme.js"

test("normalizes supported Tokyo themes", () => {
  assert.equal(normalizeTheme(DARK_THEME), DARK_THEME)
  assert.equal(normalizeTheme(LIGHT_THEME), LIGHT_THEME)
})

test("migrates legacy light and dark preferences", () => {
  assert.equal(normalizeTheme("light"), LIGHT_THEME)
  assert.equal(normalizeTheme("catppuccin-latte"), LIGHT_THEME)
  assert.equal(normalizeTheme("dark"), DARK_THEME)
  assert.equal(normalizeTheme("midnight"), DARK_THEME)
  assert.equal(normalizeTheme("dracula"), DARK_THEME)
})

test("defaults unknown values and toggles within the Tokyo pair", () => {
  assert.equal(normalizeTheme("unknown"), DARK_THEME)
  assert.equal(normalizeTheme(null), DARK_THEME)
  assert.equal(oppositeTheme(DARK_THEME), LIGHT_THEME)
  assert.equal(oppositeTheme(LIGHT_THEME), DARK_THEME)
})
