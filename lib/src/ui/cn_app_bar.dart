import 'package:flutter/material.dart';

PreferredSizeWidget cnAppBar({
  required BuildContext context,
  required VoidCallback? onLogout,
  List<Widget> extraActions = const [],
}) {
  final canPop = Navigator.of(context).canPop();

  return AppBar(
    centerTitle: true,
    title: const Text('CN Pride Point'),
    leadingWidth: canPop ? 120 : 72,
    leading: Row(
      children: [
        if (canPop)
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Image.asset(
            'assets/cn_lions_logo.png',
            width: 32,
            height: 32,
            fit: BoxFit.contain,
          ),
        ),
      ],
    ),
    actions: [
      ...extraActions,
      if (onLogout != null)
        IconButton(
          onPressed: onLogout,
          icon: const Icon(Icons.logout),
          tooltip: 'Logout',
        ),
    ],
  );
}

