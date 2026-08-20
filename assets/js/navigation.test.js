import test from "node:test"
import assert from "node:assert/strict"

import { pageForPath } from "./navigation.js"

test("maps application paths to persistent navigation sections", () => {
  assert.equal(pageForPath("/"), "home")
  assert.equal(pageForPath("/blog"), "blog")
  assert.equal(pageForPath("/blog/effective-prompts"), "blog")
  assert.equal(pageForPath("/prompts/42"), "prompts")
  assert.equal(pageForPath("/courses/liveview"), "videos")
  assert.equal(pageForPath("/videos/intro"), "videos")
  assert.equal(pageForPath("/forum/search"), "community")
  assert.equal(pageForPath("/u/uriel"), "community")
  assert.equal(pageForPath("/something-new"), "home")
})
