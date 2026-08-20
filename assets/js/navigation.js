export function pageForPath(pathname) {
  if (pathname.startsWith("/blog")) return "blog"
  if (pathname.startsWith("/prompts")) return "prompts"
  if (
    pathname.startsWith("/courses") ||
    pathname.startsWith("/videos") ||
    pathname.startsWith("/lessons")
  ) return "videos"
  if (pathname.startsWith("/forum") || pathname.startsWith("/u/")) return "community"
  return "home"
}
