class ActivityAttendanceListItem {
  const ActivityAttendanceListItem({
    required this.id,
    required this.programName,
    required this.activityName,
    required this.attendeeDisplayName,
    required this.status,
    required this.checkedInAt,
  });

  final String id;
  final String? programName;
  final String? activityName;
  final String? attendeeDisplayName;
  final String? status;
  final String? checkedInAt;
}
