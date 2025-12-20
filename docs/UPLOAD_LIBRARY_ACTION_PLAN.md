# Generic File Upload Library Implementation Plan

## Status: ✅ Core Implementation Complete

### Implemented (December 19, 2025)
- ✅ **UUID v7** support with `uniq` library
- ✅ **Polymorphic file attachments** using `entity_type` + `entity_id`
- ✅ **Files table** with all metadata fields (storage_key, original_filename, content_type, byte_size, width, height)
- ✅ **Visibility control** (public, private, participants) with DB constraint
- ✅ **Soft delete** support via `deleted_at` timestamp
- ✅ **Proper indexes** - composite on (entity_type, entity_id), partial on deleted_at
- ✅ **R2 integration** - Cloudflare R2 configured at media.urielm.dev
- ✅ **Files context** - Generic polymorphic queries for any entity type

### Remaining for v1
- [ ] LiveView upload helpers
- [ ] Svelte upload components (FileUploader, FileAttachments)
- [ ] Integration with thread/comment/post creation flows
- [ ] End-to-end testing

## Goal
Create a reusable file upload system that can attach files to any entity (forum threads, comments, posts, lectures, courses, etc.) using Cloudflare R2 storage.

## Reference Implementation
Based on the production attachment system from `~/projects/phoenix-backend` with adaptations for the urielm architecture (Phoenix LiveView + Svelte).

## Important: Cloudflare R2 API Token Behavior

**Key Discovery:** When you edit R2 API token permissions in Cloudflare (e.g., changing from "Object Read & Write" to "Admin Read & Write"), the API credentials (Access Key ID and Secret Access Key) **DO NOT change**.

**What this means:**
- You can update token permissions without regenerating credentials
- Your `.env` file credentials remain valid after permission updates
- Click "Update Account API Token" to apply permission changes
- **No need to copy new credentials** - existing ones work with new permissions
- Restart your application/IEx to pick up the permission changes

**Debugging 403 errors:**
1. Verify token permissions are what you think they are
2. Check IP filtering isn't blocking your requests
3. Restart IEx after updating token (`recompile()` or exit/restart)
4. Test specific permissions with `ExAws.S3.put_object/3` vs `list_objects/1`

## Implementation Steps

### 1. Database Schema Refactor

**Migration**: Create new migration to refactor files table

**Changes**:
- Remove `thread_id`, `comment_id` columns
- Add `entity_type` (text) - values: "thread", "comment", "post", "lecture", "course", etc.
- Add `entity_id` (text) - UUID or integer depending on entity
- Add `visibility` (text) - "public", "private", "participants"
- Add `checksum_sha256` (bytea) - for deduplication (optional for v1)
- Add `deleted_at` (timestamp) - soft delete support
- Update indexes:
  - Composite: `(entity_type, entity_id)`
  - Individual: `deleted_at`, `user_id`

**File**: `priv/repo/migrations/YYYYMMDDHHMMSS_refactor_files_to_polymorphic.exs`

### 2. Update File Schema

**File**: `lib/urielm/file.ex`

**Changes**:
- Replace `belongs_to :thread` and `belongs_to :comment` with:
  - `field :entity_type, :string`
  - `field :entity_id, :string`
  - `field :visibility, :string, default: "public"`
  - `field :deleted_at, :utc_datetime`
- Add validations:
  - `validate_required([:entity_type, :entity_id])`
  - `validate_inclusion(:entity_type, ~w(thread comment post lecture course))`
  - `validate_inclusion(:visibility, ~w(public private participants))`
- Remove hard foreign key constraints

### 3. Update Files Context

**File**: `lib/urielm/files.ex`

**New functions**:
```elixir
# Generic attachment creation
create_file(upload, user_id, entity_type, entity_id, attrs \\ %{})

# Query attachments for any entity
list_entity_files(entity_type, entity_id)

# Soft delete
soft_delete_file(%File{})

# Visibility helpers
can_access_file?(%User{}, %File{})
```

**Remove**:
- `list_thread_files/1`
- `list_comment_files/1`

Replace with generic `list_entity_files/2`.

### 4. Create Upload Behavior

**File**: `lib/urielm/uploads/uploadable.ex`

Define a behavior for entities that support file attachments:

```elixir
defmodule Urielm.Uploads.Uploadable do
  @callback entity_type() :: String.t()
  @callback entity_id(struct()) :: String.t()
  @callback can_attach?(user_id :: integer(), entity :: struct()) :: boolean()
  @callback default_visibility() :: String.t()
end
```

Modules that want to support uploads can implement this behavior.

### 5. Create Upload Helpers for LiveView

**File**: `lib/urielm_web/live/uploads/upload_helpers.ex`

Reusable functions for LiveView:

```elixir
defmodule UrielmWeb.Uploads.UploadHelpers do
  # Configure LiveView upload in mount
  def allow_upload(socket, name, opts \\ [])

  # Handle uploaded files
  def consume_uploads(socket, name, entity_type, entity_id, user_id)

  # Serialize files for Svelte
  def serialize_files(files)

  # Delete attachment
  def handle_delete_file(file_id, user_id)
end
```

### 6. Create Reusable Svelte Upload Component

**File**: `assets/svelte/FileUploader.svelte`

Generic upload component that can be embedded anywhere:

**Props**:
- `live` - LiveView hook
- `entityType` - "thread", "comment", etc.
- `entityId` - ID of the entity
- `maxFiles` - Max number of files (default: 5)
- `accept` - File types (default: images + docs)
- `showPreviews` - Boolean

**Features**:
- File picker button
- Drag-and-drop zone
- Upload progress indicators
- File preview (images show thumbnail, docs show icon)
- Delete uploaded files
- Validation (size, type)

**Events**:
- `upload_files` - Send files to server
- `delete_file` - Remove attachment

### 7. Create File Display Component

**File**: `assets/svelte/FileAttachments.svelte`

Display attached files in a clean grid:

**Props**:
- `files` - Array of file objects
- `canDelete` - Boolean (owner/admin)
- `live` - For delete events

**Features**:
- Image thumbnails with lightbox
- Document icons with download links
- Delete button for authorized users
- File metadata (size, type, uploaded by)

### 8. Integration Points

#### Thread Creation/Edit
Add FileUploader component to thread composer:
```elixir
<.svelte
  name="FileUploader"
  props={%{
    entityType: "thread",
    entityId: @thread.id,
    maxFiles: 10
  }}
  socket={@socket}
/>
```

#### Comment Replies
Add FileUploader to reply composer (optional for v1)

#### Display in Threads
Show attachments using FileAttachments component:
```elixir
<.svelte
  name="FileAttachments"
  props={%{
    files: serialize_files(@thread_files),
    canDelete: @can_edit
  }}
  socket={@socket}
/>
```

## Example Usage Flow

### 1. User uploads file to a thread
```elixir
# In ThreadLive.mount/3
socket =
  socket
  |> UploadHelpers.allow_upload(:attachments,
      accept: ~w(.jpg .png .pdf),
      max_entries: 10,
      max_file_size: 10_485_760)

# In ThreadLive.handle_event/3
def handle_event("save_thread", params, socket) do
  # Create thread
  {:ok, thread} = Forum.create_thread(...)

  # Consume uploads
  files = UploadHelpers.consume_uploads(
    socket,
    :attachments,
    "thread",
    thread.id,
    socket.assigns.current_user.id
  )

  {:noreply, redirect(socket, to: ~p"/forum/t/#{thread.id}")}
end
```

### 2. Display files on thread page
```elixir
# In ThreadLive.mount/3
files = Files.list_entity_files("thread", thread.id)

socket = assign(socket, :thread_files, UploadHelpers.serialize_files(files))

# In template
<.svelte
  name="FileAttachments"
  props={%{files: @thread_files}}
  socket={@socket}
/>
```

### 3. Attach to different entity types
```elixir
# For a lecture
Files.create_file(upload, user_id, "lecture", lecture_id)

# For a course
Files.create_file(upload, user_id, "course", course_id)

# For a post
Files.create_file(upload, user_id, "post", post_id)
```

## File Structure

```
lib/
├── urielm/
│   ├── file.ex                           # Schema (polymorphic)
│   ├── files.ex                          # Context (generic queries)
│   ├── upload.ex                         # R2 operations (existing)
│   └── uploads/
│       └── uploadable.ex                 # Behavior for entities
│
├── urielm_web/
│   └── live/
│       └── uploads/
│           └── upload_helpers.ex         # LiveView helpers

assets/svelte/
├── FileUploader.svelte                   # Reusable upload component
└── FileAttachments.svelte                # Reusable display component

priv/repo/migrations/
└── YYYYMMDDHHMMSS_refactor_files_to_polymorphic.exs
```

## Benefits

1. **Reusability**: Same upload logic works for threads, comments, posts, lectures, courses
2. **Consistency**: Unified UI/UX across all upload contexts
3. **Maintainability**: Single source of truth for upload behavior
4. **Extensibility**: Easy to add new entity types (just add to allowed list)
5. **Flexibility**: Visibility control per attachment
6. **Future-proof**: Can add presigned URLs, background processing, deduplication later

## Image Format Strategy

Based on production implementation from `phoenix-backend`:

### Upload Formats
- **Accept**: JPG, JPEG, PNG, GIF, WebP
- **Store originals as-is** in R2 (no conversion on upload)
- **Max size**: 10 MB (configurable)

### Thumbnail Generation (Optional for v1, recommended for v2)
Using **Mogrify** (ImageMagick wrapper):

```elixir
# Generate WebP thumbnails for images
Mogrify.open(source_path)
|> Mogrify.resize_to_limit("512x512")
|> Mogrify.format("webp")
|> Mogrify.save(path: dest_path)
```

**Sizes**: 512px and 128px square thumbnails
**Format**: WebP (better compression than JPG/PNG)
**Cache headers**: `cache-control: public, max-age=31536000` (1 year)

### Document Formats
- **PDF, DOC, DOCX, TXT**: Store as-is, no processing
- **Display**: Icon + download link (no previews for v1)

### Storage Pattern
```
uploads/{user_id}/{timestamp}-{uuid}-{filename}       # Original
uploads/{user_id}/{timestamp}-{uuid}-thumb_512.webp  # Large thumbnail
uploads/{user_id}/{timestamp}-{uuid}-thumb_128.webp  # Small thumbnail
```

### Migration Path
- **v1**: Store originals only, no thumbnail processing
- **v2**: Add background job (Oban) for thumbnail generation
- **v3**: Add image optimization, deduplication, OCR

## Future Enhancements (Out of Scope for v1)

- **Presigned URLs** for direct client → R2 uploads
- **Background thumbnail generation** (Oban job queue)
- **Virus scanning** integration (ClamAV/VirusTotal)
- **Image optimization** - WebP conversion, quality adjustment
- **Deduplication** via SHA256 checksums
- **Billing/quota** tracking per user
- **OCR** for scanned documents (Google Vision/Tesseract)
- **File versioning** - track edits/replacements

## Testing Checklist

- [ ] Upload file to thread
- [ ] Upload file to comment
- [ ] View files on thread page
- [ ] Delete file as owner
- [ ] Cannot delete file as non-owner
- [ ] Soft delete preserves record
- [ ] File size validation works
- [ ] File type validation works
- [ ] Files display correctly (images vs documents)
- [ ] Download files via public URL
