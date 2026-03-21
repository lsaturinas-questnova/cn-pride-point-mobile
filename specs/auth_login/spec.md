# Backend Login Integration (OAuth2 Password Grant)

## Summary
Integrate this Flutter app with a backend login endpoint at:

- `POST {HOST_URL}/oauth2/token`
- Authorization: `Basic` auth using app credentials (client id/secret)
- Body: `application/x-www-form-urlencoded` with `grant_type=password`, `username`, `password`

Primary outcome: users can sign in from the app, receive an access token, persist it securely, and the app routes users based on authenticated state.

## Goals
- Provide a login UI that collects username/password and calls the backend token endpoint.
- Allow the user to input `HOST_URL` on the login screen, persist it, and reuse it.
- Send the token request using Basic Auth for app credentials and form-urlencoded body.
- Parse and persist the received token response.
- Route users to an authenticated home screen after successful login.
- Provide logout that clears persisted auth state.

## Non-goals (for this iteration)
- Role/permission-based UI.
- Automatic environment discovery.

## API Contract
### Endpoint
- Method: `POST`
- Path: `/oauth2/token`
- Full URL: `{HOST_URL}/oauth2/token`

### Request Headers
- `Authorization: Basic {base64(clientId:clientSecret)}`
- `Content-Type: application/x-www-form-urlencoded`
- `Accept: application/json`

### Request Body (x-www-form-urlencoded)
- `grant_type=password`
- `username=<user input>`
- `password=<user input>`

### Refresh Token
If the stored token has `expires_in` and is expired, the app uses the refresh token to obtain a new access token.

Request:
- Method: `POST`
- Path: `/oauth2/token`
- Headers: same as login (`Authorization: Basic ...`, `Content-Type: application/x-www-form-urlencoded`)
- Body (x-www-form-urlencoded):
  - `grant_type=refresh_token`
  - `refresh_token=<stored refresh token>`

Response:
- Same shape as the login response. A new `refresh_token` may be returned; if present, the app replaces the stored one.

Refresh failure handling:
- If refresh returns 400/401 or missing required fields, clear stored auth and show the login screen.

### Response (expected, typical OAuth2 token response)
Fields may vary by backend; the app should be tolerant to extra fields.
- `access_token` (string, required)
- `token_type` (string, optional; default to `Bearer` for downstream usage)
- `expires_in` (number, optional)
- `refresh_token` (string, optional; required for refresh when `expires_in` is present)
- `scope` (string, optional)

Example success response:
```json
{
  "access_token": "ewmrhYuQeXsKb****AGy6",
  "refresh_token": "J6HAyzu6b4siVcLioA8Y****zxJr3ZY",
  "token_type": "Bearer",
  "expires_in": 43199
}
```

### Error Handling
- HTTP 400/401: show “Invalid credentials” when response indicates `invalid_grant` or unauthorized.
- Network/timeouts: show “Network error, try again”.
- Unexpected response shape: show “Login failed” and keep the user on the login screen.

## App Configuration
### Required runtime values
- `HOST_URL` (e.g., `https://api.example.com`) provided by the user on the login screen.
- `OAUTH_CLIENT_ID`
- `OAUTH_CLIENT_SECRET`

### Configuration approach
Use compile-time defines for app credentials. `HOST_URL` is entered by the user and is persisted only after a successful login:
- `--dart-define=OAUTH_CLIENT_ID=...`
- `--dart-define=OAUTH_CLIENT_SECRET=...`

Optional: allow a compile-time `HOST_URL` default (used as initial value on first launch), but the user can override it from the login screen.

If a `.env`-based approach is preferred later, adopt a single config provider and keep the rest of the code unchanged.

## State Management & Architecture
Keep the first implementation simple and idiomatic:
- `AuthApi`: performs HTTP call to `/oauth2/token`.
- `TokenStorage`: persists token data (secure storage).
- `AuthRepository`: coordinates API + storage and exposes `login`, `logout`, `loadSession`, and `refreshIfExpired`.
- Use Riverpod for state management and dependency injection.

Suggested providers:
- `authApiProvider`
- `tokenStorageProvider`
- `authRepositoryProvider`
- `authStateProvider` (holds current auth session state and bootstraps from storage)

Routing:
- On app start, load session from storage:
  - if access token exists:
    - if expired and refresh token exists → refresh and then show authenticated home
    - else → show authenticated home
  - else → show login

## Token Storage
Persist token data using secure storage (preferred):
- Store `access_token`, `token_type`, `expires_at` (derived from `expires_in` when available), and `refresh_token` if provided.

Expiry definition:
- If `expires_at` is present and `DateTime.now()` is past it, the token is considered expired.
- If `expires_in` is not provided (no expiry), the token is treated as non-expiring for this iteration.

Persist backend host selection:
- Persist a list of previously used `HOST_URL` values and the current selection only when login succeeds.
- On login screen load, if history exists, show a dropdown to pick a previous host (and allow entering a new one).

If secure storage is not available/desired, use a less secure fallback (shared preferences) but keep the interface (`TokenStorage`) unchanged.

## UI/UX
### Login Screen
- Host URL input (editable). If there are previous host values, show them as a dropdown for quick selection.
- Username field
- Password field (obscured)
- Submit button
- Loading state while request is in-flight
- Error banner/text for failed login

### Authenticated Home Screen
- Shows options to view/update reference lists from host:
  - Programs
  - Activities
  - Attendees
  - Sections
  - Year levels
- Each option navigates to a list screen that supports “Update from host” and displays fetched items.
- Logout action

## Security Notes
- Do not log passwords, client secrets, or tokens.
- A client secret embedded in a mobile app cannot be kept truly secret; treat this flow as “best-effort” and rely on TLS plus backend risk controls.
- Do not require HTTPS; the app may be used against local-network hosts (including IP-only hosts). When using HTTP, treat the connection as insecure and limit usage to trusted networks.

## Acceptance Criteria
- Given valid app credentials + user credentials, app receives `access_token` and routes to authenticated home.
- Given invalid credentials, app shows a clear error without crashing.
- On relaunch after successful login, app starts authenticated (token loaded from storage).
- Logout clears local auth state and returns to login screen. 
- On relaunch, the last selected `HOST_URL` is prefilled; if multiple hosts were used previously, the user can select them from a dropdown. 
