# Phase 102 Theme Backgrounds

VonoTalky now automatically checks the following files for dedicated Login/Register/Welcome backgrounds:

```text
assets/images/auth_theme_purple.jpg
assets/images/auth_theme_pink.jpg
assets/images/auth_theme_blue.jpg
assets/images/auth_theme_green.jpg
assets/images/auth_theme_orange.jpg
```

The requested visual direction is:

- Purple: purple/pink night city, VonoTalky default.
- Pink: rose/pink sunset city.
- Blue: deep-blue moon/night landscape.
- Green: teal/green aurora forest or mountain landscape.
- Orange: warm orange/red sunset mountain or city landscape.

## Important

Dedicated image files are optional in Phase 102 v1.
If they are absent, the app automatically falls back to `auth_mountain.jpg` and color-treats it with the selected theme. This means theme switching works immediately without missing-asset crashes.
