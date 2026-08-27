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

test("reply composer clears persisted drafts after submit is accepted", () => {
  const handleSubmitStart = replyComposer.indexOf("function handleSubmit()")
  const handleDiscardStart = replyComposer.indexOf("function handleDiscard()")
  const handleSubmitBlock = replyComposer.slice(handleSubmitStart, handleDiscardStart)

  assert.notEqual(handleSubmitStart, -1)
  assert.notEqual(handleDiscardStart, -1)
  assert.match(handleSubmitBlock, /onSubmit\(replyText\)/)
  assert.match(handleSubmitBlock, /clearDraft\(\)/)
  assert.ok(handleSubmitBlock.indexOf("clearDraft()") > handleSubmitBlock.indexOf("onSubmit(replyText)"))
})

test("reply composer keeps the existing keyboard shortcut affordance", () => {
  assert.match(replyComposer, /Cmd<\/kbd>\+<kbd class="kbd kbd-sm">Enter/)
})
