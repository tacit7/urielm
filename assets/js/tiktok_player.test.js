import assert from "node:assert/strict"
import test from "node:test"

import { buildTikTokPlayerUrl, extractTikTokVideoId } from "./tiktok_player.js"

test("extractTikTokVideoId accepts canonical TikTok video URLs", () => {
  assert.equal(
    extractTikTokVideoId("https://www.tiktok.com/@ask.cat-gpt/video/7675882960125431053?q=gpt"),
    "7675882960125431053"
  )
})

test("extractTikTokVideoId rejects lookalike and malformed URLs", () => {
  assert.equal(extractTikTokVideoId("https://example.com/@askcatgpt/video/7675882960125431053"), null)
  assert.equal(extractTikTokVideoId("not a url"), null)
})

test("buildTikTokPlayerUrl enables the full standard playback interface", () => {
  const playerUrl = new URL(
    buildTikTokPlayerUrl("https://www.tiktok.com/@askcatgpt/video/7675882960125431053")
  )

  assert.equal(playerUrl.pathname, "/player/v1/7675882960125431053")
  assert.equal(playerUrl.searchParams.get("controls"), "1")
  assert.equal(playerUrl.searchParams.get("progress_bar"), "1")
  assert.equal(playerUrl.searchParams.get("volume_control"), "1")
  assert.equal(playerUrl.searchParams.get("fullscreen_button"), "1")
  assert.equal(playerUrl.searchParams.get("timestamp"), "1")
  assert.equal(playerUrl.searchParams.get("closed_caption"), "1")
  assert.equal(playerUrl.searchParams.get("description"), "1")
  assert.equal(playerUrl.searchParams.get("music_info"), "1")
  assert.equal(playerUrl.searchParams.get("rel"), "0")
  assert.equal(playerUrl.searchParams.get("autoplay"), "0")
  assert.equal(playerUrl.searchParams.get("loop"), "0")
})

test("buildTikTokPlayerUrl loops fullscreen Shorts", () => {
  const playerUrl = new URL(
    buildTikTokPlayerUrl("https://www.tiktok.com/@askcatgpt/video/7675882960125431053", {
      fullscreen: true
    })
  )

  assert.equal(playerUrl.searchParams.get("loop"), "1")
})
