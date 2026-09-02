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
