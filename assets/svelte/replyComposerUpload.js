function escapeMarkdownLabel(label) {
  return label.replace(/[\\[\]]/g, "\\$&")
}

function uploadMarkdown(upload) {
  const label = escapeMarkdownLabel(upload.filename)

  if (upload.content_type.startsWith("image/")) {
    return `![${label}](${upload.url})`
  }

  return `[${label}](${upload.url})`
}

export function appendUploadsToReply(replyText, uploads) {
  return [replyText.trimEnd(), ...uploads.map(uploadMarkdown)]
    .filter(Boolean)
    .join("\n\n")
}
