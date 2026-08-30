import { readFileSync } from "node:fs"
import assert from "node:assert/strict"
import test from "node:test"

const threadCard = readFileSync(new URL("./ThreadCard.svelte", import.meta.url), "utf8")

test("thread card uses icon-based pinned and status affordances", () => {
  assert.match(threadCard, /<UMIcon name="pin"/)
  assert.match(threadCard, /<UMIcon name="check_circle"/)
  assert.match(threadCard, /<UMIcon name="lock_closed"/)
})

test("thread card keeps mobile metadata compact and desktop activity aligned", () => {
  assert.match(threadCard, /md:hidden/)
  assert.match(threadCard, /ml-auto font-mono tabular-nums/)
  assert.match(threadCard, /hidden font-mono text-xs text-base-content\/50 tabular-nums md:inline/)
})

test("thread card pluralizes compact mobile labels", () => {
  assert.match(threadCard, /function labelFor/)
  assert.match(threadCard, /labelFor\(comment_count, "reply", "replies"\)/)
  assert.match(threadCard, /labelFor\(view_count, "view"\)/)
})
