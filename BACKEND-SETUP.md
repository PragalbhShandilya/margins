# Connect the Margins community

Deployment is deferred at the owner’s request. No backend service or paid hosting has been started. Before deploying later, merge the prepared notification reliability fixes and run the feature checks.

The app remains available at https://pragalbhshandilya.github.io/margins/.

The personal library, card designer, editorial channels and in-app moments work without an account. Shared reader accounts, follow feeds and notifications while the app is closed require the server included in this repository.

## Hosted setup with Render

1. Sign in at [Render](https://dashboard.render.com/). Choose **New → Blueprint** and connect **PragalbhShandilya/margins**. Use the repository's `render.yaml`.
2. Review the proposed **paid, always-on web service and 1 GB persistent disk**, including Render's displayed cost, before choosing Deploy. Nothing has been purchased or deployed for you. Do not switch to a sleeping/free service or remove its disk: that would interrupt reminders or lose accounts.
3. Wait for the service to be Live. Open its generated HTTPS address followed by `/api/health`. It should return `"app":"margins"` and `"pushReady":true`.
4. Open [Margins](https://pragalbhshandilya.github.io/margins/). Go to **Collection & settings → Connect your community**. Paste the new server's base address, such as `https://your-service.onrender.com`, and select **Connect server**.
5. Create a username and password. Give your friend the same server address. Each person must connect to that same server and create their own account.
6. Add a quote in My library, then select **Publish** on the individual quote you want others to see. Find your friend in People, follow them, and verify their published quote appears in your reader feed. Private quotes are never published automatically.
7. In Moments, choose your collection, design, frequency and hours, enable moments, and Save. Select **Enable device notifications** and allow notifications. The selected words and schedule are uploaded privately to the server to deliver the reminders. Uploaded personal photos stay local; background notification images use the preset photo backgrounds only.
8. On iPhone/iPad, open the app in Safari and **Share → Add to Home Screen**. Launch it from the Home Screen before enabling notifications. Device support, focus modes and operating-system settings affect delivery and image appearance. Verify on the actual phone with the app closed.

The server generates Web Push keys once and stores them on its persistent disk. It never prints the private key. Optional VAPID environment variables can override this for an existing installation. Do not change keys later without re-subscribing devices.

## Local development

Use Node.js 24.19 or a later Node 24 release.

```sh
npx --yes pnpm@11.25.0 install --frozen-lockfile --ignore-scripts
node --test tests/*.test.mjs
node backend/server.mjs
```

Open `http://localhost:8787`. For a separately served interface on port 8766, add that origin to `ALLOWED_ORIGINS`. If serving the interface from this backend, set `ALLOWED_ORIGINS` to its own origin as well. In production always use HTTPS. The repository's server serves only allowlisted app files; it never serves database files or backend source.

## Configuration and operation

- `DATABASE_PATH`: SQLite database on a persistent disk; default `./data/margins.sqlite` for local development.
- `ALLOWED_ORIGINS`: comma-separated **origins**, no trailing slash. The provided blueprint allows the existing GitHub Pages site. Add your backend's own HTTPS origin only if you also want to serve the interface there.
- `VAPID_SUBJECT`: a real HTTPS contact URL or `mailto:` contact. The blueprint uses the app's public URL. Setting this enables automatic key generation.
- `TRUST_PROXY=1`: only behind a reverse proxy that replaces `X-Forwarded-For`; otherwise keep `0`.
- `PORT`: supplied by hosting; local default 8787.

Use **one instance**, because the SQLite database and delivery loop are on the same persistent disk. Keep the service always running. Jobs survive restarts; overdue jobs are skipped outside quiet hours. Times use the device's submitted IANA timezone, not the server clock's local timezone. Save moments again after travelling to update the server's timezone. Delivery is best effort, polled every 15 seconds, with bounded retries. This is not a time-critical alarm service.

Take regular SQLite-consistent backups using SQLite's online backup tooling, or stop the service before copying the database, WAL and SHM files together. Protect backups: the database contains account hashes, push subscriptions, selected private reminder quotes and Web Push keys. Backups are an owner responsibility; disk persistence alone is not a backup.

## Account and privacy behavior

- Account sessions expire after seven days. The browser keeps the token in session storage. Passwords use salted scrypt hashes; tokens are hashed in the database.
- Profile name and bio, username and explicitly published quotes are public on the connected community server. Anyone with its address can read those public quotes.
- Your whole library is not an account sync service. Use Export/Import to transfer private collections between devices.
- Server-side reminders store a private snapshot of the selected quote pool. Save moments again to update it after changing your collection. Own uploaded photos are not uploaded to the server.
- Signing out or disconnecting pauses this account's background reminders on **all devices**. The controls also pause local in-app reminders. If the server cannot confirm a stop request, the app keeps the connection and credentials for retry and warns that background reminders may continue. Pause removes the server subscriptions; use Enable device notifications to reconnect when resuming.
- There is no email/password recovery yet. Keep the password in your password manager. An owner-run account recovery and abuse-moderation flow is required before opening registration to a wider public audience.

## Acceptance before declaring every feature 8/10

The local implementation and test suite are prepared. Production accounts/following and background delivery must remain below 8/10 until:

- This server is hosted with durable storage and HTTPS.
- Two separate devices create accounts on it, publish only intended quotes, follow/unfollow and see the right feed.
- A real opted-in device receives a random moment with the app closed, within its selected quiet-hours window.
- Pause, signout, denied notification permission and restarting the host are verified on the deployed service.

Sources checked for this setup: [Render Blueprint reference](https://render.com/docs/blueprint-spec), [persistent disks](https://render.com/docs/disks), [Apple Web Push requirements](https://webkit.org/blog/13878/), and the [Web Push library](https://github.com/web-push-libs/web-push).
