# Checklist: Backend Login Integration

## API
- [ ] Uses `POST {HOST_URL}/oauth2/token`
- [ ] Sends `Authorization: Basic base64(clientId:clientSecret)`
- [ ] Sends `Content-Type: application/x-www-form-urlencoded`
- [ ] Sends body `grant_type=password&username=...&password=...` (URL-encoded)
- [ ] Refreshes token with `grant_type=refresh_token` when expired
- [ ] Handles 200/400/401/5xx and network failures gracefully

## App Behavior
- [ ] Shows login screen when no saved token exists
- [ ] On successful login, navigates to authenticated home
- [ ] Persists token securely and restores session on app restart
- [ ] If token is expired and refresh token exists, refreshes before authenticating
- [ ] Logout clears token and returns to login
- [ ] Persists `HOST_URL` only after successful login and restores last selection on app restart
- [ ] Shows `HOST_URL` dropdown when previous hosts exist
- [ ] Uses Riverpod for auth state and routing decisions

## UI/UX
- [ ] Login form validates required fields
- [ ] Login button shows loading state and prevents double-submit
- [ ] Error states are visible and actionable
- [ ] Host URL input supports free entry and selecting past values

## Security
- [ ] No secrets/tokens/passwords are logged
- [ ] Supports HTTP for trusted local-network hosts (including IP-only)

## Tests
- [ ] Unit tests cover request encoding and header formation
- [ ] Unit tests cover common error responses
- [ ] Widget test covers login success and login failure UI states
