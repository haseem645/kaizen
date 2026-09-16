# Google sign-in

The Login button opens Google in the external browser using `url_launcher`.
`GoogleAuthorizationDataSource` listens through `app_links` for the verified HTTPS
callback, validates a fresh random `state`, and returns the single-use code.
Cancel, denied consent, timeout, and callbacks from older attempts do not create a session.

`GoogleLoginUseCase` sends the code through `AuthRepository` to:

```http
POST /api/v1/accounts/google/login/
Content-Type: application/json

{"code":"<fresh authorization code>","redirect_uri":"https://dev.kaizenteams.ai/auth/google/callback"}
```

The response must include nonempty string `access` and `refresh` app tokens.
The shared `LoginSessionUseCase` persists those tokens, fetches the user profile,
and initializes company/organization data exactly as password login does.
If profile initialization fails, the partial app session is cleared.
Existing authenticated deep-link navigation runs after successful login.

## Configuration

Development defaults match the public configuration served by
`https://dev.kaizenteams.ai/assets/googleOAuth-580ea6d8.js`.
The OAuth client ID is public; the Google client secret remains on the backend.
Only `openid email profile` is requested; this does not request Gmail access.

### Platform OAuth configuration

The supplied `android-client.json` and `ios-client.plist` belong to OAuth project
`kaizen-teams` (`273718420607`). Their public client IDs are configured separately
from Firebase Messaging, which uses project `kaizenteams` (`417334653237`). Do not
replace `google-services.json` or `GoogleService-Info.plist` with these OAuth exports.

| Purpose | Client ID | Configuration location |
| --- | --- | --- |
| Android registration | `273718420607-hlfcopqref984gkjpedid02h1cl05sgi.apps.googleusercontent.com` | Google Cloud Android client for `com.kaizenteam` and its signing certificate; recorded in `android/app/src/main/res/values/google_sign_in.xml` |
| iOS client | `273718420607-ome8m3n16fs468u05dbettnmts6n7om9.apps.googleusercontent.com` | `GIDClientID` in `ios/Runner/Info.plist` |
| Web/backend client | `273718420607-sma08mj14celj9c4dshthl3nbeqttb12.apps.googleusercontent.com` | Existing Dart browser configuration, Android `default_web_client_id`, and iOS `GIDServerClientID` |

The iOS `REVERSED_CLIENT_ID` is registered as an additional URL scheme in
`ios/Runner/Info.plist`, alongside the existing `kaizenteams` scheme. Its bundle ID
matches `com.kaizenteam`.

Android resolves its native OAuth registration by package name and signing
certificate; the Android client ID is not a `serverClientId` or a replacement for
the browser's Web client ID. The supplied Android export does not include a package
name or signing fingerprint, so these must be checked in Google Cloud. Android
`default_web_client_id` uses the existing Web client because the current Firebase
configuration contains no Web OAuth entry. If an updated `google-services.json`
generates this resource later, remove the manual resource to avoid a duplicate.

These platform settings prepare native Google Sign-In configuration only. The
login button still uses the browser flow described above, and the project does not
include `google_sign_in`. Switching that flow requires native SDK integration and
verification that the backend accepts the resulting credentials. These settings
do not replace the HTTPS app-link associations required by the current flow.

### Browser configuration

For a different environment, provide `GOOGLE_OAUTH_CLIENT_ID` and
`GOOGLE_OAUTH_REDIRECT_URI` using Dart defines. The backend and Google's registered
redirect must use that exact URI. Update the Android callback intent filter and
iOS associated domain when changing the callback host/path.

The dev domain already publishes Android app links and an iOS association covering
`/auth/*`. The installed Android signing certificate must match its published
`/.well-known/assetlinks.json`; additional debug/release signing certificates need
to be registered there. The iOS app ID must match its published association.
The web callback should not exchange a mobile attempt's code before the app receives it.

Validate real Google login on an associated Android/iOS build, including return
from the browser, cancel, wrong-account rejection, and the post-login destination.
If the OS kills the app while the browser is open, restart sign-in: the previous
in-memory state is intentionally not accepted by a new app instance.

References:
- https://developers.google.com/identity/protocols/oauth2/web-server
- https://pub.dev/packages/google_sign_in_android
- https://pub.dev/packages/google_sign_in_ios
- https://dev.kaizenteams.ai/.well-known/apple-app-site-association
- https://dev.kaizenteams.ai/.well-known/assetlinks.json
