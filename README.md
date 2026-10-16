# Margins

A warm, book-inspired home for words worth keeping.

**[Open the app](https://pragalbhshandilya.github.io/margins/)** · [Feature scorecard](QA-SCORECARD.md) · [Connect the backend](BACKEND-SETUP.md)

## Personal collection

Add quotes from books, films, friends or family. Edit, favorite, search, sort and remove with undo. Explore serious and funny editorial channels; follow them for a personal feed and reminder choices. Design cards with a preset background or your own image and save them as PNGs. Plan random in-app moments inside your quiet hours. Export and import backups.

Personal data is stored on the current device. Existing prototype collections migrate to stable quote IDs. Invalid stored data is preserved for recovery. Import merges rather than replacing existing quotes.

## Community and background moments

A Node 24 + SQLite backend implements real accounts, explicitly published quotes, reader discovery, following and a shared feed. A durable Web Push scheduler handles random slots, timezones, quiet hours, retries and expired subscriptions. The backend is prepared and tested locally, **not yet deployed**. The owner has deferred backend deployment. The latest readiness candidate has 37 passing checks, including offline sign-out and pause retries. GitHub Pages serves the interface only.

Use [the setup guide](BACKEND-SETUP.md) to connect it. A Render Blueprint is included; deploying it creates paid resources, which the owner must review first. Device delivery still requires a real phone acceptance test. Account recovery and moderation remain pre-public-launch work.

## Development

Open the app through an HTTP static server or run `node backend/server.mjs` after installing dependencies. No client build step is needed.

```sh
npx --yes pnpm@11.25.0 install --frozen-lockfile --ignore-scripts
node --test tests/*.test.mjs
node backend/server.mjs
```

GitHub Pages publishes from `main`. The feature-check workflow runs the Node test suite. Photos use Unsplash; imported images remain on the device. Curated quote attributions with uncertain provenance are explicitly marked.
