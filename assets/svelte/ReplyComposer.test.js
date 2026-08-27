import test from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"

const replyComposer = readFileSync(new URL("./ReplyComposer.svelte", import.meta.url), "utf8")

test("reply composer persists and restores drafts from localStorage", () => {
  assert.match(replyComposer, /draftKey = null/)
  assert.match(replyComposer, /localStorage\.getItem\(draftKey\)/)
  assert.match(replyComposer, /localStorage\.setItem\(draftKey, replyText\)/)
  assert.match(replyComposer, /localStorage\.removeItem\(draftKey\)/)
  assert.match(replyComposer, /draftHydrated/)
})

test("reply composer keeps the existing keyboard shortcut affordance", () => {
  assert.match(replyComposer, /Cmd<\/kbd>\+<kbd class="kbd kbd-sm">Enter/)
})
