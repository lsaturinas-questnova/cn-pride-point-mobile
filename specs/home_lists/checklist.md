# Checklist: Home Screen Lists

## UI
- [ ] Home screen shows: Programs, Activities, Activity Attendance List, Attendees, Sections, Year levels
- [ ] Each option is tappable and navigates to a list screen
- [ ] List screen shows title matching entity name
- [ ] List screen supports refresh (“Update from host”)
- [ ] Loading and error states are clearly shown
- [ ] Activity Attendance List prompts for Program and optional Activity before opening
- [ ] Activity Attendance List scan is enabled only when Program and Activity selected
- [ ] Activity Attendance List shows sync button for pending local records
- [ ] Pending attendance item opens details screen to edit notes
- [ ] Long-press pending attendance item confirms delete

## Data
- [ ] List retrieval uses the persisted `HOST_URL`
- [ ] Reference entities are persisted in SQLite after refresh
- [ ] Programs uses `GET {HOST_URL}/attendance/programs?page=0&size=2&sort=name&dir=ASC`
- [ ] Programs response parsing reads `content` list
- [ ] Activities uses `GET {HOST_URL}/attendance/activities?page=0&size=2&sort=name&dir=ASC`
- [ ] Activities response parsing reads `content` list
- [ ] Year levels uses `GET {HOST_URL}/attendance/year-levels?page=0&size=2&sort=name&dir=ASC`
- [ ] Year levels response parsing reads `content` list
- [ ] Sections uses `GET {HOST_URL}/attendance/sections?page=1&size=2&sort=name&dir=ASC`
- [ ] Sections response parsing reads `content` list
- [ ] Attendees uses `GET {HOST_URL}/attendance/attendees?page=0&size=2&sort=lastName&dir=ASC`
- [ ] Attendees response parsing reads `content` list and tolerates nullable yearLevel/section/profilePic
- [ ] Activity Attendance List uses `GET {HOST_URL}/attendance/activity-attendance-list?page=0&size=2&sort=attendee&dir=ASC`
- [ ] Activity Attendance List supports `programId` (required) and `activityId` (optional)
- [ ] Activity Attendance List response parsing reads `content` list and tolerates relations
- [ ] Scan looks up attendee by `code` from persisted attendees
- [ ] Scan creates local pending attendance record without backend id
- [ ] Offline attendance record has unique `mobileReference`
- [ ] Sync posts pending records to `POST {HOST_URL}/attendance/sync`
- [ ] Sync validates response via `mobileReference` and requires non-null `id`
- [ ] Sync sets syncStatus to ERROR and stores lastSyncError on failures
- [ ] Sync shows notification when response has errors = true
- [ ] Error handling supports retry

## State Management
- [ ] Uses Riverpod providers for list loading state

## Tests
- [ ] Navigation test covers all list options
- [ ] List state tests cover loading, success, error, retry
