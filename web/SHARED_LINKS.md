# Website dialog store action

The flow is:

- A tapped link can open the installed app through the existing verified deep links.
- When the link opens in a browser, including when the app is absent, the website loads normally.
- Pasting a link into the browser leaves the visitor on the website.
- Clicking the website's existing dialog button opens the official store for the device.

`shared_link_store_fallback.js` only exposes `getStoreUrl()` and `openStore()`.
It creates no dialog and performs no action when loaded. It does not try to open
the app, detect installation, inspect the referrer or start a fallback timer.
Existing mobile deep-link routes continue to handle app opening.

## Website setup and TypeScript fix

1. Replace the frontend's `public/shared_link_store_fallback.js` with this script.
   Keep one script tag before the frontend application scripts, with an updated
   version to avoid the previous cached behavior:

   ```html
   <script src="/shared_link_store_fallback.js?v=4"></script>
   ```

2. Copy `shared_link_store_fallback.d.ts` into the frontend as
   `src/types/shared_link_store_fallback.d.ts`. This declaration adds
   `KaizenSharedLinks` to TypeScript's `Window` interface, resolving
   `Property 'KaizenSharedLinks' does not exist on type 'Window & typeof globalThis'`.
   Ensure the frontend's `tsconfig.json` includes `src` (or `src/**/*.d.ts`). A
   declaration placed only in `public/` is normally outside the TypeScript source
   set. Keep `export {}` in the declaration file; no runtime import is required.
   This uses TypeScript's [global augmentation](https://www.typescriptlang.org/docs/handbook/declaration-merging.html#global-augmentation).

3. Connect the existing dialog button to this React/TypeScript click handler:

   ```tsx
   const handleDialogButtonClick = () => {
     window.KaizenSharedLinks?.openStore();
   };

   // On the existing button:
   // onClick={handleDialogButtonClick}
   ```

   Keep navigation inside the click handler. Do not call `openStore()` during
   rendering, mounting, script load or in a timer. Keep the existing dialog's
   dismiss action and its design.

4. Remove old automatic redirects, duplicate prompt scripts and earlier
   `getLinks()` / `openAppUrl` integrations. Deploy the website changes together.

`getStoreUrl()` returns the device's official store URL without navigating;
`openStore()` navigates to that URL and returns `true`. Both support Android,
iPhone, iPad (including its desktop user agent), and iPod. On desktop or an
unknown device, `getStoreUrl()` returns `null` and `openStore()` returns `false`
without navigation. If the website uses an anchor for its store action, use
`getStoreUrl()` for the `href` and set `referrerPolicy="no-referrer"`.

Store URLs are fixed:

- https://apps.apple.com/us/app/kaizenteams/id6773032580
- https://play.google.com/store/apps/details?id=com.kaizenteam

The click action is independent of the current page path, so it works for shared
paygrades, shared seat profiles, shared LMS, verification, organization and auth
pages, including after client-side navigation. Loading any of these pages never
triggers a store visit. No mobile update is needed for this website-only change.

The actual website dialog is in the separate frontend repository. This Flutter
repository supplies the script and declaration; it does not automatically bind
or deploy the existing website button.

## Verification

```sh
node --test test/web/shared_link_store_fallback_test.cjs
```

From this repository, use an available TypeScript compiler to check the script,
declaration and strict TypeScript consumer together:

```sh
tsc --noEmit --strict --allowJs --checkJs --lib ES2020,DOM web/shared_link_store_fallback.js web/shared_link_store_fallback.d.ts test/web/shared_link_store_fallback_types_test.ts
```

After website deployment, check pasted URLs and links from email/messages with
and without the app installed. Browser visits must stay on the website, and only
the existing dialog button should navigate to the appropriate store. Keep the
verified app associations configured for direct opening of installed apps.
