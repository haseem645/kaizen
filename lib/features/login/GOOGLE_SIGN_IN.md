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
- https://dev.kaizenteams.ai/.well-known/apple-app-site-association
- https://dev.kaizenteams.ai/.well-known/assetlinks.json
