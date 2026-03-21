# Tasks: Home Screen Lists

## Implementation Tasks
1. Implement authenticated home screen options for all entities.
2. Add navigation from home options to entity list screens.
3. Implement list screen UI (loading, empty, error, retry, refresh).
4. Add Riverpod state for list loading and refresh.
5. Implement list repositories/APIs that load from current `HOST_URL`.
6. Add SQLite persistence for reference entities.
7. Implement Programs list API integration and response parsing.
8. Implement Activities list API integration and response parsing.
9. Implement Year levels list API integration and response parsing.
10. Implement Sections list API integration and response parsing.
11. Implement Attendees list API integration and response parsing.
12. Implement Activity Attendance List API integration and response parsing.
13. Implement Activity Attendance scan flow and offline queue.
14. Implement Activity Attendance sync of pending records.
15. Add mobileReference generation and sync validation logic.
16. Add Activity Attendance details screen with notes editing.
17. Add delete flow for offline attendance records.
18. Add sync error notification when response has errors.
19. Add basic tests for navigation and list state transitions (mocked data layer).

## Verification Tasks
- Verify home screen shows all list options.
- Verify each option opens the correct list screen title.
- Verify list screens load on open and can refresh on demand.
- Verify loading disables refresh and prevents double-fetch.
- Verify error state shows message and retry works.
- Verify `HOST_URL` is used as the base for requests.
- Verify reference entities are persisted in SQLite after refresh.
- Verify scan creates a local pending Activity Attendance record without backend id.
- Verify sync posts all pending records and marks them synced on success.
- Verify mobileReference is unique and included in sync payload.
- Verify sync marks record ERROR and stores lastSyncError when id missing.
- Verify notes can be edited and are included in sync payload.
- Verify user can delete offline attendance record after confirmation.
- Verify sync shows notification when response has errors = true.
