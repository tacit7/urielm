export const primaryNavItems = [
  { page: "videos", label: "Videos", href: "/videos" },
  { page: "courses", label: "Courses", href: "/courses" },
  { page: "blog", label: "Blog", href: "/blog" },
  { page: "prompts", label: "Prompts", href: "/prompts" },
  { page: "community", label: "Community", href: "/forum" },
]

export const mobileMoreItems = primaryNavItems.filter(({ page }) =>
  ["courses", "blog", "prompts"].includes(page),
)

export function profilePathForUser(user) {
  const username = user?.username?.trim()
  return username ? `/u/${encodeURIComponent(username)}` : "/profile"
}

export function pageForPath(pathname) {
  if (pathname.startsWith("/blog")) return "blog"
  if (pathname.startsWith("/code-kata")) return "code-kata"
  if (pathname.startsWith("/prompts")) return "prompts"
  if (pathname.startsWith("/videos")) return "videos"
  if (pathname.startsWith("/courses") || pathname.startsWith("/lessons")) return "courses"
  if (pathname.startsWith("/forum") || pathname.startsWith("/u/")) return "community"
  return "home"
}
