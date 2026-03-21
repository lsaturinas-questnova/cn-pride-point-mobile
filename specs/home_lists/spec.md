# Home Screen Lists (Update From Host)

## Summary
After a successful login, the app shows an authenticated home screen with options to view and update reference lists from the configured backend host (`HOST_URL`). Selecting an option opens a list screen for that entity.

Entities:
- Programs
- Activities
- Activity Attendance List
- Attendees
- Sections
- Year levels

## Goals
- Provide a home screen that exposes the list options.
- On option press, navigate to a list screen dedicated to that entity.
- Allow the user to manually update (refresh) the list from the current `HOST_URL`.
- Show loading and error states for list retrieval.

## Non-goals (for this iteration)
- Offline-first behavior and local database caching.
- Advanced filtering/sorting/search.
- Create/edit/delete flows for entities.

## Definitions
- Host: the `HOST_URL` persisted from the last successful login.
- Update list: fetch the latest list from the backend host and render it in the list screen.

## Navigation
- Login success → Home screen
- Home option press → Entity list screen

## UI/UX
### Home Screen
- Title (e.g., “Home”)
- Shows actions (as buttons or list tiles):
  - Programs
  - Activities
  - Activity Attendance List
  - Attendees
  - Sections
  - Year levels
- Each action navigates to its list screen.

### Entity List Screen (Programs/Activities/Activity Attendance List/Attendees/Sections/Year levels)
- Screen title matches entity name.
- Primary action: “Update from host” (refresh button).
- On screen open: automatically loads the list once.
- States:
  - Loading: show progress indicator and disable update action.
  - Success: show a scrollable list; empty state is allowed.
  - Failure: show an error message with a retry action.

## Data & API Contract
The app uses the current `HOST_URL` to load lists. Endpoint paths and response models are backend-defined and may differ by environment.

For this iteration:
- Define a single data layer entry point per entity (repository function) that returns a list of items suitable for display.
- Treat endpoint paths and item fields as TBD until backend contracts are confirmed, except where specified below.
- Persist reference entities locally in SQLite; do not automatically persist Activity Attendance List API results.

## Local Persistence (SQLite)
Persist reference entities in SQLite to support offline usage and fast lookup. These are treated as local cache of backend data.

Persisted entities:
- Programs
- Activities
- Attendees
- Sections
- Year levels

Local entity rules:
- Use the backend `id` as the primary identifier in local tables (string UUID).
- Upsert on refresh (insert if missing; update existing by id).
- Do not delete locally unless the backend provides a deletion marker and a retention policy is defined.

### Offline Activity Attendance
Locally created Activity Attendance records are persisted in SQLite as an offline queue for later submission to the backend.

Rules:
- Activity Attendance List API results are not automatically persisted as historical records.
- When scanning and creating a new attendance record, store it locally even if there is no backend `id` yet.
- When scanning and creating a new attendance record, generate a unique `mobileReference` using `<username>-<timestamp>` (example: `admin-1710982700000`).
- A local record must have a local primary key (e.g., auto-increment integer or generated UUID). The backend `id` is optional and nullable until synced.
- When a local record is successfully synced:
  - set `syncStatus = SYNCED`
  - store the returned backend id to `remoteId` if provided by the backend
- When sync fails for a record:
  - keep `syncStatus = PENDING` or set to `ERROR` (if error is record-specific)
  - store a short error string in `lastSyncError` (prefer response `notes` if present)

Recommended fields for local Activity Attendance queue:
- `localId` (primary key, local-only)
- `remoteId` (nullable string UUID)
- `mobileReference` (string, unique, required)
- `programId` (string UUID)
- `activityId` (string UUID)
- `attendeeId` (string UUID)
- `checkedInAt` (ISO-8601 datetime)
- `checkedOutAt` (nullable ISO-8601 datetime)
- `status` (string; e.g., PRESENT)
- `notes` (nullable string)
- `syncStatus` (string; e.g., PENDING, SYNCED, FAILED)
- `lastSyncError` (nullable string)

### Programs API
#### Endpoint
- Method: `GET`
- Full URL (initial request): `{HOST_URL}/attendance/programs?page=0&size=2&sort=name&dir=ASC`

#### Request Headers
- `Authorization: Bearer <access_token>`
- `Accept: application/json`

#### Response
The response is a paged result with the actual list under `content`.

Expected fields:
- `content` (array)
  - Each item includes:
    - `id` (string, UUID)
    - `name` (string)
    - `type` (string)
    - `startDate` (string, `yyyy-MM-dd`)
    - `endDate` (string, `yyyy-MM-dd`)
    - `status` (string)
    - Other metadata fields may be present and should be tolerated.
- Pagination metadata fields may include `pageable`, `totalPages`, `totalElements`, `size`, `number`, `last`, `first`, `empty`.

Example response:
```json
{
  "content": [
    {
      "id": "019cccdb-7ef9-7ee8-9fa9-6f2364dd0d3c",
      "version": 3,
      "createdBy": "admin",
      "createdDate": "2026-03-08T17:51:42+08:00",
      "lastModifiedBy": "admin",
      "lastModifiedDate": "2026-03-08T17:53:04+08:00",
      "deletedBy": null,
      "deletedDate": null,
      "name": "2026 Nursing Days",
      "type": "SPORTS",
      "startDate": "2026-03-30",
      "endDate": "2026-04-01",
      "otherDetails": "Other Details",
      "status": "ACTIVE"
    }
  ],
  "pageable": {
    "pageNumber": 0,
    "pageSize": 2,
    "sort": {
      "empty": false,
      "sorted": true,
      "unsorted": false
    },
    "offset": 0,
    "paged": true,
    "unpaged": false
  },
  "last": true,
  "totalPages": 1,
  "totalElements": 1,
  "first": true,
  "size": 2,
  "number": 0,
  "sort": {
    "empty": false,
    "sorted": true,
    "unsorted": false
  },
  "numberOfElements": 1,
  "empty": false
}
```

### Activities API
#### Endpoint
- Method: `GET`
- Full URL (initial request): `{HOST_URL}/attendance/activities?page=0&size=2&sort=name&dir=ASC`

#### Request Headers
- `Authorization: Bearer <access_token>`
- `Accept: application/json`

#### Response
The response is a paged result with the actual list under `content`.

Expected fields:
- `content` (array)
  - Each item includes:
    - `id` (string, UUID)
    - `name` (string)
    - `activityType` (string)
    - `startDate` (string, ISO-8601 datetime)
    - `endDate` (string, ISO-8601 datetime)
    - `status` (string)
    - Other metadata fields may be present and should be tolerated.
- Pagination metadata fields may include `pageable`, `totalPages`, `totalElements`, `size`, `number`, `last`, `first`, `empty`.

Example response:
```json
{
  "content": [
    {
      "id": "019ccc92-63a7-73be-a375-b03dcb0453c6",
      "version": 4,
      "createdBy": "admin",
      "createdDate": "2026-03-08T16:35:51+08:00",
      "lastModifiedBy": "admin",
      "lastModifiedDate": "2026-03-08T22:03:48+08:00",
      "deletedBy": null,
      "deletedDate": null,
      "name": "Volleyball (Level 1 vs Level 2)",
      "startDate": "2026-03-07T16:30:00",
      "endDate": "2026-03-08T17:00:00",
      "activityType": "SPORT",
      "status": "ACTIVE",
      "details": null
    }
  ],
  "pageable": {
    "pageNumber": 0,
    "pageSize": 2,
    "sort": {
      "empty": false,
      "sorted": true,
      "unsorted": false
    },
    "offset": 0,
    "paged": true,
    "unpaged": false
  },
  "last": true,
  "totalPages": 1,
  "totalElements": 1,
  "first": true,
  "size": 2,
  "number": 0,
  "sort": {
    "empty": false,
    "sorted": true,
    "unsorted": false
  },
  "numberOfElements": 1,
  "empty": false
}
```

### Year levels API
#### Endpoint
- Method: `GET`
- Full URL (initial request): `{HOST_URL}/attendance/year-levels?page=0&size=2&sort=name&dir=ASC`

#### Request Headers
- `Authorization: Bearer <access_token>`
- `Accept: application/json`

#### Response
The response is a paged result with the actual list under `content`.

Expected fields:
- `content` (array)
  - Each item includes:
    - `id` (string, UUID)
    - `name` (string)
    - `status` (string)
    - Other metadata fields may be present and should be tolerated.
- Pagination metadata fields may include `pageable`, `totalPages`, `totalElements`, `size`, `number`, `last`, `first`, `empty`.

Example response:
```json
{
  "content": [
    {
      "id": "019ccc86-3363-71bc-8667-7415eef9907f",
      "version": 2,
      "createdBy": "admin",
      "createdDate": "2026-03-08T16:18:04+08:00",
      "lastModifiedBy": "admin",
      "lastModifiedDate": "2026-03-09T00:28:22+08:00",
      "deletedBy": null,
      "deletedDate": null,
      "name": "Level 1",
      "status": "ACTIVE"
    },
    {
      "id": "019ccc86-64ae-7e35-8d9f-c76773cf26b6",
      "version": 2,
      "createdBy": "admin",
      "createdDate": "2026-03-08T16:18:10+08:00",
      "lastModifiedBy": "admin",
      "lastModifiedDate": "2026-03-09T00:28:27+08:00",
      "deletedBy": null,
      "deletedDate": null,
      "name": "Level 2",
      "status": "ACTIVE"
    }
  ],
  "pageable": {
    "pageNumber": 0,
    "pageSize": 2,
    "sort": {
      "empty": false,
      "sorted": true,
      "unsorted": false
    },
    "offset": 0,
    "paged": true,
    "unpaged": false
  },
  "totalPages": 2,
  "totalElements": 4,
  "last": false,
  "size": 2,
  "number": 0,
  "sort": {
    "empty": false,
    "sorted": true,
    "unsorted": false
  },
  "numberOfElements": 2,
  "first": true,
  "empty": false
}
```

### Sections API
#### Endpoint
- Method: `GET`
- Full URL (initial request): `{HOST_URL}/attendance/sections?page=1&size=2&sort=name&dir=ASC`

#### Request Headers
- `Authorization: Bearer <access_token>`
- `Accept: application/json`

#### Response
The response is a paged result with the actual list under `content`.

Expected fields:
- `content` (array)
  - Each item includes:
    - `id` (string, UUID)
    - `name` (string)
    - `status` (string)
    - Other metadata fields may be present and should be tolerated.
- Pagination metadata fields may include `pageable`, `totalPages`, `totalElements`, `size`, `number`, `last`, `first`, `empty`.

Example response:
```json
{
  "content": [
    {
      "id": "019ccc89-145e-715f-abb7-5fb3fdca16d1",
      "version": 2,
      "createdBy": "admin",
      "createdDate": "2026-03-08T16:21:09+08:00",
      "lastModifiedBy": "admin",
      "lastModifiedDate": "2026-03-09T00:27:55+08:00",
      "deletedBy": null,
      "deletedDate": null,
      "name": "Section C",
      "status": "ACTIVE"
    },
    {
      "id": "019ccc89-3478-7bc3-80cf-ec710ab6cffb",
      "version": 2,
      "createdBy": "admin",
      "createdDate": "2026-03-08T16:21:14+08:00",
      "lastModifiedBy": "admin",
      "lastModifiedDate": "2026-03-09T00:28:00+08:00",
      "deletedBy": null,
      "deletedDate": null,
      "name": "Section D",
      "status": "ACTIVE"
    }
  ],
  "pageable": {
    "pageNumber": 1,
    "pageSize": 2,
    "sort": {
      "empty": false,
      "sorted": true,
      "unsorted": false
    },
    "offset": 2,
    "paged": true,
    "unpaged": false
  },
  "totalPages": 3,
  "totalElements": 6,
  "last": false,
  "size": 2,
  "number": 1,
  "sort": {
    "empty": false,
    "sorted": true,
    "unsorted": false
  },
  "numberOfElements": 2,
  "first": false,
  "empty": false
}
```

### Attendees API
#### Endpoint
- Method: `GET`
- Full URL (initial request): `{HOST_URL}/attendance/attendees?page=0&size=2&sort=lastName&dir=ASC`

#### Request Headers
- `Authorization: Bearer <access_token>`
- `Accept: application/json`

#### Response
The response is a paged result with the actual list under `content`.

Expected fields:
- `content` (array)
  - Each item includes:
    - `id` (string, UUID)
    - `code` (string, optional)
    - `lastName` (string)
    - `firstName` (string)
    - `middleName` (string, optional)
    - `birthdate` (string, `yyyy-MM-dd`, nullable)
    - `gender` (string, nullable)
    - `attendeeType` (string)
    - `shirtSize` (string, nullable)
    - `yearLevel` (object, nullable) optional relation to a year level
      - `id`, `name`, `status` (minimum fields for display)
    - `section` (object, nullable) optional relation to a section
      - `id`, `name`, `status` (minimum fields for display)
    - `profilePic` (object, nullable)
      - `storageName` (string)
      - `path` (string)
      - `fileName` (string)
      - `parameters` (object)
      - `contentType` (string)
    - `displayName` (string, optional)
    - `age` (number, optional)
    - Other metadata fields may be present and should be tolerated.
- Pagination metadata fields may include `pageable`, `totalPages`, `totalElements`, `size`, `number`, `last`, `first`, `empty`.

Example response:
```json
{
  "content": [
    {
      "id": "019cef17-7251-7d4c-aa32-dae4d5b5daf9",
      "version": 1,
      "createdBy": "admin",
      "createdDate": "2026-03-15T09:23:37+08:00",
      "lastModifiedBy": null,
      "lastModifiedDate": "2026-03-15T09:23:37+08:00",
      "deletedBy": null,
      "deletedDate": null,
      "code": "22501275",
      "lastName": "ACANTILADO",
      "firstName": "KURT JAMES",
      "middleName": "Midle Name",
      "birthdate": "2023-03-03",
      "gender": "MALE",
      "attendeeType": "STUDENT",
      "shirtSize": "LARGE",
      "yearLevel": {
        "id": "019ccc86-3363-71bc-8667-7415eef9907f",
        "version": 2,
        "createdBy": "admin",
        "createdDate": "2026-03-08T16:18:04+08:00",
        "lastModifiedBy": "admin",
        "lastModifiedDate": "2026-03-09T00:28:22+08:00",
        "deletedBy": null,
        "deletedDate": null,
        "name": "Level 1",
        "status": "ACTIVE"
      },
      "section": {
        "id": "019ccc87-14ef-7fc4-8745-fc20f52930f1",
        "version": 3,
        "createdBy": "admin",
        "createdDate": "2026-03-08T16:19:31+08:00",
        "lastModifiedBy": "admin",
        "lastModifiedDate": "2026-03-08T17:31:06+08:00",
        "deletedBy": null,
        "deletedDate": null,
        "name": "Section A",
        "status": "ACTIVE"
      },
      "profilePic": {
        "storageName": "fs",
        "path": "2026/03/08/b5f01ff7-a3a3-c285-5cd2-16d2471ecfd4.png",
        "fileName": "samplePng.png",
        "parameters": {},
        "contentType": "image/png"
      },
      "status": "ACTIVE",
      "displayName": "22501275 - ACANTILADO KURT JAMES M.",
      "age": 3
    },
    {
      "id": "019cef17-7302-72f2-9afe-0f98abf19a1c",
      "version": 1,
      "createdBy": "admin",
      "createdDate": "2026-03-15T09:23:37+08:00",
      "lastModifiedBy": null,
      "lastModifiedDate": "2026-03-15T09:23:37+08:00",
      "deletedBy": null,
      "deletedDate": null,
      "code": "22300192",
      "lastName": "ADOLFO",
      "firstName": "ALEXANDRA MARIE",
      "middleName": "",
      "birthdate": null,
      "gender": null,
      "attendeeType": "STUDENT",
      "shirtSize": null,
      "yearLevel": {
        "id": "019ccc86-3363-71bc-8667-7415eef9907f",
        "version": 2,
        "createdBy": "admin",
        "createdDate": "2026-03-08T16:18:04+08:00",
        "lastModifiedBy": "admin",
        "lastModifiedDate": "2026-03-09T00:28:22+08:00",
        "deletedBy": null,
        "deletedDate": null,
        "name": "Level 1",
        "status": "ACTIVE"
      },
      "section": {
        "id": "019ccc87-14ef-7fc4-8745-fc20f52930f1",
        "version": 3,
        "createdBy": "admin",
        "createdDate": "2026-03-08T16:19:31+08:00",
        "lastModifiedBy": "admin",
        "lastModifiedDate": "2026-03-08T17:31:06+08:00",
        "deletedBy": null,
        "deletedDate": null,
        "name": "Section A",
        "status": "ACTIVE"
      },
      "profilePic": null,
      "status": "ACTIVE",
      "displayName": "22300192 - ADOLFO ALEXANDRA MARIE",
      "age": 0
    }
  ],
  "pageable": {
    "pageNumber": 0,
    "pageSize": 2,
    "sort": {
      "empty": false,
      "sorted": true,
      "unsorted": false
    },
    "offset": 0,
    "paged": true,
    "unpaged": false
  },
  "totalPages": 3,
  "totalElements": 5,
  "last": false,
  "size": 2,
  "number": 0,
  "sort": {
    "empty": false,
    "sorted": true,
    "unsorted": false
  },
  "numberOfElements": 2,
  "first": true,
  "empty": false
}
```

### Activity Attendance List API
#### Endpoint
- Method: `GET`
- Full URL (initial request): `{HOST_URL}/attendance/activity-attendance-list?page=0&size=2&sort=attendee&dir=ASC`

#### Query Parameters
- `programId` (string UUID, required)
- `activityId` (string UUID, optional)

Example:
`/attendance/activity-attendance-list?page=0&size=2&sort=attendee&dir=ASC&programId=019d0b83-a23e-7e40-be36-58ff87284db0&activityId=019ccc92-63a7-73be-a375-b03dcb0453c6`

#### Request Headers
- `Authorization: Bearer <access_token>`
- `Accept: application/json`

#### Screen Behavior
- Before opening the Activity Attendance List screen, prompt the user to select:
  - Program (required)
  - Activity (optional)
- On the screen, show dropdown fields for Program and Activity:
  - Changing either updates the query parameters (`programId`, `activityId`) and refreshes the list.
- The scan button is enabled only when both Program and Activity are selected.
- Add a sync button:
  - Enabled when there is at least one local offline attendance record with `syncStatus = PENDING`.
  - Submits pending records to the backend `/attendance/sync`.

#### Barcode Scanning (CODE39)
- When scan is pressed, open the camera and scan a CODE39 barcode from a student ID.
- Use the scanned value to look up an attendee by `code` from persisted attendees in SQLite.
- If an attendee is found, create a new local Activity Attendance record using:
  - selected Program
  - selected Activity
  - matched Attendee
  - `checkedInAt = DateTime.now()`
  - `syncStatus = PENDING`
- If no attendee matches the scanned code, show a clear error and do not create a record.

#### Sync API
##### Endpoint
- Method: `POST`
- Full URL: `{HOST_URL}/attendance/sync`

##### Request Headers
- `Authorization: Bearer <access_token>`
- `Content-Type: application/json`
- `Accept: application/json`

##### Request Body
Send an array of records derived from the local offline queue where `syncStatus = PENDING`.

Mapping rules:
- `id` is sent as `null` when the record has not been synced before.
- `program.id`, `activity.id`, and `attendee.id` are sent using local `programId`, `activityId`, `attendeeId`.
- `checkedInAt`, `checkedOutAt`, `status`, `notes` are sent as stored locally.
- `mobileReference` is sent as stored locally (used to validate which records were successfully synced).

Example request body:
```json
[
  {
    "id": null,
    "program": {
      "id": "019cccdb-7ef9-7ee8-9fa9-6f2364dd0d3c"
    },
    "activity": {
      "id": "019ccc92-63a7-73be-a375-b03dcb0453c6"
    },
    "checkedInAt": "2026-03-08T16:00:00",
    "checkedOutAt": null,
    "attendee": {
      "id": "019cce55-fba6-7ff8-b4e8-4ac554892f0e"
    },
    "status": "PRESENT",
    "notes": null,
    "mobileReference": "admin-1710982700000"
  }
]
```

##### Sync Result Handling
- Validate sync results using `mobileReference`:
  - When a response item with matching `mobileReference` has a non-empty `id`, mark that local record `SYNCED` and set `remoteId = id`.
  - When a response item has matching `mobileReference` but `id` is null/empty, mark that local record `ERROR` and set `lastSyncError` from response `notes` (or a default message).
- If the response has `"errors": true`, show a user notification that sync has errors.

##### Response
Expected response shape:
- `attendanceList` (array)
  - each item includes:
    - `id` (string, nullable)
    - `notes` (string, nullable)
    - `mobileReference` (string)
- `errors` (boolean)

Example response:
```json
{
  "attendanceList": [
    {
      "id": "c26ee4e5-af49-4549-b499-8c08803c2f5d",
      "program": { "id": "019cccdb-7ef9-7ee8-9fa9-6f2364dd0d3c" },
      "activity": { "id": "019ccc92-63a7-73be-a375-b03dcb0453c6" },
      "checkedInAt": "2026-03-08T16:00:00",
      "checkedOutAt": null,
      "attendee": { "id": "019cce55-fba6-7ff8-b4e8-4ac554892f0e" },
      "status": "PRESENT",
      "notes": null,
      "mobileReference": "admin-timestamp"
    }
  ],
  "errors": false
}
```

#### Offline Attendance UI
- Pending (local) list shows locally created Activity Attendance records.
- On tap of a pending item, open an Activity Attendance Details screen:
  - show key fields (Program, Activity, Attendee, checkedInAt, status, mobileReference, syncStatus)
  - allow editing `notes` and saving it to local storage
- On long-press of a pending item, show a confirmation dialog to delete the record.

## State Management
Use Riverpod for list state:
- One provider per entity list screen or a parameterized provider keyed by entity type.
- Provider exposes:
  - `items` (list)
  - `isLoading`
  - `error` (nullable)
  - `refresh()` / `load()`

## Acceptance Criteria
- Home screen shows options: Programs, Activities, Activity Attendance List, Attendees, Sections, Year levels.
- Tapping any option opens a list screen for that entity.
- Each list screen loads once on open and supports “Update from host”.
- List requests use the currently selected/persisted `HOST_URL`.
- Errors are visible and user can retry without restarting the app.
- Reference entities are persisted in SQLite and can be used for offline lookup.
- Activity Attendance scan creates a local pending record even without backend `id`.
- Activity Attendance offline records have unique `mobileReference` and notes can be edited.
- Sync validates success via `mobileReference` and sets record `SYNCED` or `ERROR`.
- If sync response has `errors = true`, user sees a sync error notification.
