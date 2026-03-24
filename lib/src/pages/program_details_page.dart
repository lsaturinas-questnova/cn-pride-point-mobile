import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/providers.dart';
import '../models/entities.dart';
import '../ui/date_format.dart';
import '../ui/cn_app_bar.dart';

class ProgramDetailsPage extends ConsumerWidget {
  const ProgramDetailsPage({super.key, required this.program});

  final Program program;

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
                program.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _row('Type', program.type),
              _row('Start', formatDateTimeStringYmdHm(program.startDate)),
              _row('End', formatDateTimeStringYmdHm(program.endDate)),
              _row('Status', program.status),
              _row('Details', program.otherDetails),
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
          SizedBox(width: 70, child: Text('$label:')),
          Expanded(child: Text(v.isEmpty ? '-' : v)),
        ],
      ),
    );
  }
}
