# FamilyTasks — Help / Tutorial

User-facing HTML manual (English + Russian).

## Open

| Entry | Behavior |
|-------|----------|
| **[index.html](./index.html)** | Default → **English** (`en/index.html`). Remembers last language in `localStorage`. |
| [en/index.html](./en/index.html) | English home |
| [ru/index.html](./ru/index.html) | Russian home |

Double-click `index.html` or open in a browser.

## Structure

```
Help/Tutorial/   (source of truth for docs)
assets/help/     (copy bundled in the app; open via Settings → Help)

Sync to app assets after editing EN/RU HTML:
  Copy-Item Help\Tutorial\* assets\help\ -Recurse -Force
  # then bump HelpManualExtractor.version in lib/features/help/

Help/Tutorial/
  index.html          # language router (default EN)
  assets/
    tutorial.css
    lang.js
  en/                 # English chapters
  ru/                 # Russian chapters (same set)
```

## After each product iteration

1. Update **both** `en/07-whats-new.html` and `ru/07-whats-new.html` (summary + detail section if needed).
2. Add or extend the matching feature chapter in **EN and RU** (e.g. `02-tasks.html` for list features).
3. Keep UI labels in English (as in the app).
4. Bump the home page card blurbs if the chapter scope grew.

### Iteration 9 (done in guide)

- Search, default sort, long-press sheet, assignee avatars → `en|ru/02-tasks.html` + `07-whats-new.html`

### Iteration 10 (done in guide)

- Family onboarding dialogs, first-assign tip, Personal/Family help, creator-only edit banner → `03-create-edit`, `04-family`, `07-whats-new`

### Iteration 11 (done in guide)

- Invite 7-day TTL, regenerate revokes old, weekly recurrence spawn on Done → `03-create-edit`, `04-family`, `07-whats-new`
- Iter 12: Daily/Monthly repeat, share family summary, skeletons, haptics → `03-create-edit`, `05-dashboard`, `07-whats-new`
