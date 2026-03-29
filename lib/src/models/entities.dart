class Program {
  const Program({
    required this.id,
    required this.name,
    this.type,
    this.startDate,
    this.endDate,
    this.status,
    this.otherDetails,
  });

  final String id;
  final String name;
  final String? type;
  final String? startDate;
  final String? endDate;
  final String? status;
  final String? otherDetails;
}

class Activity {
  const Activity({
    required this.id,
    required this.name,
    this.activityType,
    this.startDate,
    this.endDate,
    this.status,
    this.details,
  });

  final String id;
  final String name;
  final String? activityType;
  final String? startDate;
  final String? endDate;
  final String? status;
  final String? details;
}

class ActivitySchedule {
  const ActivitySchedule({
    required this.id,
    required this.programId,
    required this.activityId,
    this.startDate,
    this.endDate,
    this.status,
    this.notes,
  });

  final String id;
  final String programId;
  final String activityId;
  final String? startDate;
  final String? endDate;
  final String? status;
  final String? notes;
}

class YearLevel {
  const YearLevel({required this.id, required this.name, this.status});

  final String id;
  final String name;
  final String? status;
}

class Section {
  const Section({required this.id, required this.name, this.status});

  final String id;
  final String name;
  final String? status;
}

class Attendee {
  const Attendee({
    required this.id,
    this.code,
    this.lastName,
    this.firstName,
    this.middleName,
    this.displayName,
    this.yearLevelId,
    this.sectionId,
    this.profilePicJson,
    this.status,
    this.attendeeType,
    this.shirtSize,
    this.gender,
  });

  final String id;
  final String? code;
  final String? lastName;
  final String? firstName;
  final String? middleName;
  final String? displayName;
  final String? yearLevelId;
  final String? sectionId;
  final String? profilePicJson;
  final String? status;
  final String? attendeeType;
  final String? shirtSize;
  final String? gender;
}

enum SyncStatus { pending, synced, error }

class OfflineAttendance {
  const OfflineAttendance({
    required this.localId,
    required this.activityScheduleId,
    required this.attendeeId,
    required this.mobileReference,
    required this.checkedInAt,
    required this.status,
    required this.syncStatus,
    this.remoteId,
    this.checkedOutAt,
    this.notes,
    this.lastSyncError,
  });

  final int localId;
  final String? remoteId;
  final String activityScheduleId;
  final String attendeeId;
  final String mobileReference;
  final DateTime checkedInAt;
  final DateTime? checkedOutAt;
  final String status;
  final String? notes;
  final SyncStatus syncStatus;
  final String? lastSyncError;
}
