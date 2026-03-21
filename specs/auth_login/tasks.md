# Tasks: Backend Login Integration

## Implementation Tasks
1. Add app configuration for `OAUTH_CLIENT_ID`, `OAUTH_CLIENT_SECRET`.
2. Add persistent `HOST_URL` history and selection for login screen.
2. Add HTTP client dependency and implement `AuthApi` for `/oauth2/token`.
3. Implement `TokenStorage` (secure storage) and `AuthRepository` login/logout/loadSession/refresh.
4. Add Riverpod dependency and implement auth providers/state.
5. Wire app routing (login vs authenticated home) via Riverpod state.
5. Build login screen UI with host dropdown/input, validation, loading, and error states.
6. Add authenticated home screen with logout.
7. Add unit tests for token request formatting, refresh flow, and error mapping.
8. Add widget tests for login screen happy path and error path (mocked API).

## Verification Tasks
- Verify request includes:
  - `Authorization: Basic ...`
  - `Content-Type: application/x-www-form-urlencoded`
  - Body contains `grant_type=password` and provided `username`/`password`
- Verify token request uses the selected `HOST_URL`.
- Verify `HOST_URL` history persists only after successful login and populates the dropdown on relaunch.
- Verify refresh occurs when stored token is expired and refresh token exists.
- Verify refresh failure clears auth and returns to login.
- Verify token persistence across app restart.
- Verify logout clears persisted token.
