# Architecture

Feature-first layout. Each feature owns its data, domain, and presentation; cross-cutting
code lives in `core/`; the app shell (entry, future router/providers) lives at the top.

```
lib/
  main.dart                 # bootstrap: Firebase init + runApp
  core/                     # cross-cutting, no feature-specific imports
    theme/                  # colors, ThemeProvider (design system — do not change)
    utils/                  # logger, ScaffoldMessenger extension, share helpers
    widgets/                # shared widgets (CustomImageHolder, buttons, fields)
  features/
    auth/        { data/ , presentation/ }
    auctions/    { data/ , domain/ , presentation/ }
    bids/        { data/ , domain/ , presentation/ }
    watchlist/   { data/ , domain/ , presentation/ }
    notifications/ { data/ , domain/ , presentation/ }
    profile/     { data/ , domain/ , presentation/ }
    shell/       { presentation/ }   # bottom-nav container (navigation_page)
    support/     { presentation/ }   # static privacy / help screens
```

## Dependency direction

```
presentation  →  data  →  Firestore / Firebase
     │            │
     └────────────┴──────────────→  core (theme, utils, widgets, domain models)
```

Rules:

- `presentation/` depends on its own feature's `data/` and `domain/`, and on `core/`.
  It never reaches `FirebaseFirestore.instance` directly — only through a repository.
- `data/` (repositories) wraps Firestore queries and returns `domain/` models.
- A feature must not import another feature's `presentation/`. Cross-feature reuse goes
  through `core/` or through a repository in the other feature's `data/`.
- `core/` depends on nothing app-specific (no `features/` imports).

## Layer glossary

- **domain/** — immutable data classes (`fromFirestore` / `toMap`). No Flutter, no Firebase
  SDK calls beyond `DocumentSnapshot` parsing.
- **data/** — repositories: one per collection, all Firestore access lives here.
- **presentation/** — screens and feature-local widgets.

See `PROMPT.md` for the v1.1 roadmap (image upload, FCM push, routing, UI/UX, observability).