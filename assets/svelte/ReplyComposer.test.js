import test from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import { appendUploadsToReply } from "./replyComposerUpload.js"

const replyComposer = readFileSync(new URL("./ReplyComposer.svelte", import.meta.url), "utf8")

test("reply composer persists and restores drafts from localStorage", () => {
  assert.match(replyComposer, /draftKey = null/)
  assert.match(replyComposer, /localStorage\.getItem\(draftKey\)/)
  assert.match(replyComposer, /localStorage\.setItem\(draftKey, replyText\)/)
  assert.match(replyComposer, /localStorage\.removeItem\(draftKey\)/)
  assert.match(replyComposer, /draftHydrated/)
  assert.match(replyComposer, /if \(!isOpen\) \{\s+draftHydrated = false/)
})

test("reply composer clears persisted drafts after submit is accepted", () => {
  const handleSubmitStart = replyComposer.indexOf("function handleSubmit()")
  const handleDiscardStart = replyComposer.indexOf("function handleDiscard()")
  const handleSubmitBlock = replyComposer.slice(handleSubmitStart, handleDiscardStart)

  assert.notEqual(handleSubmitStart, -1)
  assert.notEqual(handleDiscardStart, -1)
  assert.match(handleSubmitBlock, /await onSubmit\(submissionText\)/)
  assert.match(handleSubmitBlock, /clearDraft\(\)/)
  assert.ok(
    handleSubmitBlock.indexOf("clearDraft()") >
      handleSubmitBlock.indexOf("await onSubmit(submissionText)")
  )
})

test("reply composer keeps the existing keyboard shortcut affordance", () => {
  assert.match(replyComposer, /Cmd<\/kbd>\+<kbd class="kbd kbd-sm">Enter/)
})

test("reply composer renders a markdown preview and multipart upload control", () => {
  assert.match(replyComposer, /import MarkdownRenderer from "\.\/MarkdownRenderer\.svelte"/)
  assert.match(replyComposer, /aria-label="Preview reply"/)
  assert.match(replyComposer, /type="file"/)
  assert.match(replyComposer, /multiple/)
  assert.match(replyComposer, /new FormData\(\)/)
  assert.match(replyComposer, /fetch\(uploadUrl/)
})

test("successful image and document uploads are appended as markdown", () => {
  assert.equal(
    appendUploadsToReply("See the files.", [
      {
        filename: "diagram.png",
        content_type: "image/png",
        url: "https://files.example/diagram.png"
      },
      {
        filename: "notes.pdf",
        content_type: "application/pdf",
        url: "https://files.example/notes.pdf"
      }
    ]),
    "See the files.\n\n![diagram.png](https://files.example/diagram.png)\n\n[notes.pdf](https://files.example/notes.pdf)"
  )
})

test("discard clears pending uploads along with the persisted draft", () => {
  const handleDiscardStart = replyComposer.indexOf("function handleDiscard()")
  const checkMobileStart = replyComposer.indexOf("function checkMobile()")
  const handleDiscardBlock = replyComposer.slice(handleDiscardStart, checkMobileStart)

  assert.match(handleDiscardBlock, /selectedFiles = \[\]/)
  assert.match(handleDiscardBlock, /uploadError = ""/)
  assert.match(handleDiscardBlock, /clearDraft\(\)/)
})
