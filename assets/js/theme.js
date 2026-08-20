export const DARK_THEME = "tokyo-night"
export const LIGHT_THEME = "tokyo-day"

const LIGHT_LEGACY_THEMES = new Set([
  LIGHT_THEME,
  "light",
  "catppuccin-latte",
  "github-light",
  "cupcake",
  "bumblebee",
  "emerald",
  "corporate",
  "retro",
  "valentine",
  "garden",
  "lofi",
  "pastel",
  "fantasy",
  "wireframe",
  "cmyk",
  "autumn",
  "acid",
  "lemonade",
  "winter"
])

export function normalizeTheme(theme) {
  return LIGHT_LEGACY_THEMES.has(theme) ? LIGHT_THEME : DARK_THEME
}

export function oppositeTheme(theme) {
  return normalizeTheme(theme) === DARK_THEME ? LIGHT_THEME : DARK_THEME
}
