// LiveView updates the body during navigation; keep the document head in sync
// with the metadata emitted by the current root LiveView.
export function syncSeoMetadata(metadata, document) {
  const title = metadata.page_title || "Urielm"
  document.title = `${title} · urielm.dev`

  const tags = [
    ["name", "description", metadata.meta_description],
    ["name", "robots", metadata.robots],
    ["property", "og:title", metadata.og_title || title],
    ["property", "og:description", metadata.og_description || metadata.meta_description],
    ["property", "og:url", metadata.og_url || metadata.canonical_url],
    ["property", "og:type", metadata.og_type || "website"],
    ["property", "og:site_name", metadata.og_site_name || "Urielm"],
    ["property", "og:image", metadata.og_image],
    ["name", "twitter:card", metadata.twitter_card || "summary"],
    ["name", "twitter:title", metadata.twitter_title || title],
    ["name", "twitter:description", metadata.twitter_description || metadata.meta_description],
    ["name", "twitter:image", metadata.twitter_image]
  ]

  for (const [attribute, name, content] of tags) {
    replaceTag(document, "meta", attribute, name, "content", content)
  }

  replaceTag(document, "link", "rel", "canonical", "href", metadata.canonical_url)

  for (const node of document.head.querySelectorAll('script[type="application/ld+json"]')) {
    node.remove()
  }

  for (const json of metadata.json_ld || []) {
    const node = document.createElement("script")
    node.type = "application/ld+json"
    node.textContent = json
    document.head.appendChild(node)
  }
}

function replaceTag(document, tag, attribute, name, valueAttribute, value) {
  const existing = [...document.head.querySelectorAll(`${tag}[${attribute}="${name}"]`)]
  const node = existing.shift()
  existing.forEach(duplicate => duplicate.remove())

  if (!value) {
    node?.remove()
    return
  }

  const target = node || document.createElement(tag)
  target.setAttribute(attribute, name)
  target.setAttribute(valueAttribute, value)
  if (!node) document.head.appendChild(target)
}

export const SEOHead = {
  mounted() { this.sync() },
  updated() { this.sync() },
  sync() {
    syncSeoMetadata(JSON.parse(this.el.dataset.seo), this.el.ownerDocument)
  }
}
