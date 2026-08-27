import test from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"

const commentTree = readFileSync(new URL("./CommentTree.svelte", import.meta.url), "utf8")

test("comment tree forwards a stable draft key to the reply composer", () => {
  assert.match(commentTree, /reply_draft_key = null/)
  assert.match(commentTree, /draftKey=\{reply_draft_key\}/)
})
