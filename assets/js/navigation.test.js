import test from "node:test"
import assert from "node:assert/strict"

import {
  mobileMoreItems,
  pageForPath,
  primaryNavItems,
  profilePathForUser,
} from "./navigation.js"

test("maps application paths to persistent navigation sections", () => {
  assert.equal(pageForPath("/"), "home")
  assert.equal(pageForPath("/blog"), "blog")
  assert.equal(pageForPath("/blog/effective-prompts"), "blog")
  assert.equal(pageForPath("/code-kata"), "code-kata")
  assert.equal(pageForPath("/prompts/42"), "prompts")
  assert.equal(pageForPath("/courses/liveview"), "courses")
  assert.equal(pageForPath("/videos/intro"), "videos")
  assert.equal(pageForPath("/forum/search"), "community")
  assert.equal(pageForPath("/u/uriel"), "community")
  assert.equal(pageForPath("/something-new"), "home")
})

test("keeps primary and mobile secondary destinations distinct", () => {
  assert.deepEqual(primaryNavItems.map(item => item.page), [
    "videos",
    "courses",
    "blog",
    "prompts",
    "community",
  ])

  assert.deepEqual(mobileMoreItems.map(item => item.page), ["courses", "blog", "prompts"])
  assert.equal(mobileMoreItems.some(item => item.page === "videos"), false)
  assert.equal(mobileMoreItems.some(item => item.page === "community"), false)
})

test("builds a safe profile destination", () => {
  assert.equal(profilePathForUser({ username: "uriel" }), "/u/uriel")
  assert.equal(profilePathForUser({ username: "" }), "/profile")
  assert.equal(profilePathForUser(null), "/profile")
})
