import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/providers.dart';
import '../models/entities.dart';
import '../ui/cn_app_bar.dart';
import '../ui/date_format.dart';

class ActivityScheduleDetailsPage extends ConsumerWidget {
  const ActivityScheduleDetailsPage({
    super.key,
    required this.schedule,
    required this.programName,
    required this.activityName,
  });

  final ActivitySchedule schedule;
  final String? programName;
  final String? activityName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: cnAppBar(
        context: context,
        onLogout: () => ref.read(authSessionProvider.notifier).logout(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (activityName ?? '').trim().isEmpty ? '-' : activityName!.trim(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _row('Program', programName),
              _row('Start', formatDateTimeStringYmdHm(schedule.startDate)),
              _row('End', formatDateTimeStringYmdHm(schedule.endDate)),
              _row('Status', schedule.status),
              _row('Notes', schedule.notes),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String? value) {
    final v = (value ?? '').trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text('$label:')),
          Expanded(child: Text(v.isEmpty ? '-' : v)),
        ],
      ),
    );
  }
}

