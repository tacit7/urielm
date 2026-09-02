import test from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"

const markdownRenderer = readFileSync(
  new URL("./MarkdownRenderer.svelte", import.meta.url),
  "utf8"
)

test("markdown renderer linkifies bare external urls", () => {
  assert.match(markdownRenderer, /linkify:\s*true/)
})

test("markdown renderer intercepts local video timestamp links", () => {
  assert.match(markdownRenderer, /localTimestampVideoId/)
  assert.match(markdownRenderer, /urielm:video-seek/)
  assert.match(markdownRenderer, /href\.startsWith\('#t='\)/)
})
