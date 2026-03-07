# Security Review (High Priority)

## Status: ✅ ALL ISSUES RESOLVED (2025-12-25)

## Findings & Fixes

### 1. ✅ FIXED: Stored XSS via Markdown (threads)
**Issue:** `assets/svelte/MarkdownRenderer.svelte` rendered MarkdownIt output directly with `{@html html}` without sanitization.

**Fix Applied:**
- Installed DOMPurify sanitizer library
- Added HTML sanitization with strict allowlist of safe tags/attributes
- Blocked dangerous protocols (`javascript:`, `data:`)
- Stripped event handler attributes (`onerror`, `onclick`, etc.)
- Changed `enableEmbeds` default to `false` for user content

### 2. ✅ FIXED: Soft-deleted threads still readable
**Issue:** `lib/urielm/forum.ex:get_thread!/2` did not filter `is_removed`.

**Fix Applied:**
- Added `allow_removed?` option to `get_thread!/2`
- Raises `Ecto.NoResultsError` (404) for removed threads unless `allow_removed?: true`
- Updated `ThreadLive` to pass `allow_removed?: true` only for admin users

### 3. ✅ ALREADY FIXED: Comment parent integrity
**Issue was already resolved:** `validate_parent_thread/2` in `create_comment/3` validates parent belongs to same thread.

### 4. ✅ ALREADY FIXED: Locked boards not enforced
**Issue was already resolved:** `create_thread/3` checks `board.is_locked` and returns `{:error, :board_locked}`.

## Regression Tests Recommended
- Sanitized Markdown: XSS payloads stripped
- Soft-deleted thread access: 404 for non-admins, visible to admins
- Cross-thread parent rejection: already covered by `validate_parent_thread/2`
- Locked-board thread creation rejection: already covered by `create_thread/3`
