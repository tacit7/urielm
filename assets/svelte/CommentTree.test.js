import test from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"

const commentTree = readFileSync(new URL("./CommentTree.svelte", import.meta.url), "utf8")

test("comment tree forwards a stable draft key to the reply composer", () => {
  assert.match(commentTree, /reply_draft_key = null/)
  assert.match(commentTree, /draftKey=\{reply_draft_key\}/)
})

test("comment tree waits for an accepted reply and forwards the upload endpoint", () => {
  assert.match(commentTree, /reply_upload_url = null/)
  assert.match(commentTree, /uploadUrl=\{reply_upload_url\}/)
  assert.match(commentTree, /"create_composer_reply"/)
  assert.match(commentTree, /response\?\.ok/)
  assert.match(commentTree, /resolve\(true\)/)
})
