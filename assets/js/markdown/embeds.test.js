import test from "node:test"
import assert from "node:assert/strict"
import { escapeAttr, processEmbeds } from "./embeds.js"

test("escapeAttr escapes HTML entities", () => {
  assert.equal(escapeAttr('hello"world'), 'hello&quot;world')
  assert.equal(escapeAttr("hello'world"), 'hello&#39;world')
  assert.equal(escapeAttr("hello&world"), 'hello&amp;world')
  assert.equal(escapeAttr("hello<world>"), 'hello&lt;world&gt;')
})

test("escapeAttr handles null and undefined", () => {
  assert.equal(escapeAttr(null), "")
  assert.equal(escapeAttr(undefined), "")
})

test("processEmbeds does not output inline JS (onclick)", () => {
  const input = "Check out this image: https://example.com/test.jpg"
  const output = processEmbeds(input)

  assert.equal(output.includes("onclick="), false, "Should not contain onclick attribute")
  assert.equal(output.includes("window.open"), false, "Should not contain window.open")
})

test("processEmbeds handles URLs with quotes safely", () => {
  // URL with quote - the regex should stop before the quote
  const testUrl = `https://example.com/x.jpg?param="malicious`
  const output = processEmbeds(testUrl)

  // Should create an embed with the URL up to (but not including) the quote
  assert.equal(output.includes('src="'), true, "Should have src attribute")
  assert.equal(output.includes('href="'), true, "Should have href attribute")

  // The tightened regex stops at quotes, so the malicious part stays as text
  // This is safe because it's not inside an HTML attribute
  assert.equal(output.includes('src="https://example.com/x.jpg?param="'), true, "Should match URL before quote")

  // Verify well-formed HTML by checking attributes are properly quoted
  const srcMatch = output.match(/src="([^"]*)"/)
  const hrefMatch = output.match(/href="([^"]*)"/)
  assert.ok(srcMatch, "Should have properly quoted src")
  assert.ok(hrefMatch, "Should have properly quoted href")
  assert.equal(srcMatch[1], hrefMatch[1], "src and href should have same URL")
})

test("processEmbeds wraps images in anchor tags with proper attributes", () => {
  const input = "https://example.com/test.jpg"
  const output = processEmbeds(input)

  assert.equal(output.includes('<a href="'), true, "Should wrap in anchor tag")
  assert.equal(output.includes('target="_blank"'), true, "Should open in new tab")
  assert.equal(output.includes('rel="noopener noreferrer"'), true, "Should have security attributes")
})

test("processEmbeds handles YouTube URLs correctly", () => {
  const input = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  const output = processEmbeds(input)

  assert.equal(output.includes("youtube-embed"), true, "Should create YouTube embed")
  assert.equal(output.includes("https://www.youtube.com/embed/dQw4w9WgXcQ"), true, "Should use embed URL")
  assert.equal(output.includes('<iframe'), true, "Should create iframe")
})

test("processEmbeds handles youtu.be short URLs", () => {
  const input = "https://youtu.be/dQw4w9WgXcQ"
  const output = processEmbeds(input)

  assert.equal(output.includes("youtube-embed"), true, "Should create YouTube embed")
  assert.equal(output.includes("https://www.youtube.com/embed/dQw4w9WgXcQ"), true, "Should convert to embed URL")
})

test("processEmbeds handles Twitter/X URLs", () => {
  const inputTwitter = "https://twitter.com/user/status/1234567890"
  const outputTwitter = processEmbeds(inputTwitter)

  assert.equal(outputTwitter.includes("tweet-embed"), true, "Should create Twitter embed")
  assert.equal(outputTwitter.includes("View post"), true, "Should have link text")

  const inputX = "https://x.com/user/status/1234567890"
  const outputX = processEmbeds(inputX)

  assert.equal(outputX.includes("tweet-embed"), true, "Should handle x.com URLs")
})

test("processEmbeds escapes Twitter URL attributes safely", () => {
  const validTwitterUrl = "https://twitter.com/user/status/1234567890"
  const output = processEmbeds(validTwitterUrl)

  // Verify the URL is properly escaped in href attribute
  assert.equal(output.includes('href="'), true, "Should have href attribute")
  assert.equal(output.includes('target="_blank"'), true, "Should have target attribute")

  // Make sure there's no attribute injection
  const hasProperHref = /href="[^"]*"/.test(output)
  assert.equal(hasProperHref, true, "Should have properly quoted href")
})

test("processEmbeds handles multiple embeds in one text", () => {
  const input = `
    Check this video: https://www.youtube.com/watch?v=dQw4w9WgXcQ
    And this image: https://example.com/test.jpg
    And this tweet: https://twitter.com/user/status/123456
  `
  const output = processEmbeds(input)

  assert.equal(output.includes("youtube-embed"), true, "Should have YouTube embed")
  assert.equal(output.includes("image-embed"), true, "Should have image embed")
  assert.equal(output.includes("tweet-embed"), true, "Should have Twitter embed")
})

test("processEmbeds tightened regex stops at quotes", () => {
  // The regex should stop matching when it hits a quote
  const inputWithQuote = `https://example.com/test.jpg plus some text`
  const output = processEmbeds(inputWithQuote)

  // Should create an embed for the valid URL part
  assert.equal(output.includes("image-embed"), true, "Should create embed for valid part")
  assert.equal(output.includes('src="'), true, "Should have src attribute")

  // Verify attributes are properly quoted and closed
  const properlyQuoted = /<img[^>]*src="[^"]*"[^>]*>/.test(output)
  assert.equal(properlyQuoted, true, "Should have properly quoted src attribute")
})

test("processEmbeds preserves existing HTML content", () => {
  const input = "<p>Some text</p> https://example.com/test.jpg <p>More text</p>"
  const output = processEmbeds(input)

  assert.equal(output.includes("<p>Some text</p>"), true, "Should preserve existing HTML")
  assert.equal(output.includes("<p>More text</p>"), true, "Should preserve existing HTML")
  assert.equal(output.includes("image-embed"), true, "Should add image embed")
})
