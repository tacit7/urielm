# Tokyo Theme Pair Design

## Goal

Give the entire application one recognizable color identity with matching light and dark modes derived from the Tokyo Night palette.

## Themes

- `tokyo-night`: deep navy page and surface colors with Tokyo blue, violet, cyan, green, amber, and red accents.
- `tokyo-day`: cool lavender-gray page and surface colors with darker Tokyo blue, violet, and cyan accents for accessible contrast.

## Behavior

- Theme preference is restricted to `tokyo-night` and `tokyo-day`.
- The preference persists through the existing `phx:theme` localStorage key and `phx_theme` cookie.
- Existing `dark`, `midnight`, `tokyo-night`, and other dark-theme preferences migrate to `tokyo-night`; existing light-theme preferences migrate to `tokyo-day`.
- All theme controls use the same custom `phx:set-theme` event.
- The server-rendered root defaults to `tokyo-night` to avoid an unthemed first paint.

## UI

- Anonymous navigation gets a compact day/night toggle next to authentication actions.
- Authenticated navigation keeps the toggle inside the user menu.
- Settings and the dedicated themes page present the same two choices.

## Reference

The palette reference is `priv/static/mockups/tokyo-theme-pair.html`.
