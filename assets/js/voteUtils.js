/**
 * Pushes a vote event to the LiveView server.
 *
 * @param {object} live - LiveSvelte live object
 * @param {string} target_type - e.g. "thread", "prompt", "comment"
 * @param {string|number} target_id - ID of the target
 * @param {number} value - 1 (upvote) or -1 (downvote)
 */
export function handleVote(live, target_type, target_id, value) {
  if (!live) return
  live.pushEvent("vote", {
    target_type,
    target_id: String(target_id),
    value: String(value)
  })
}
