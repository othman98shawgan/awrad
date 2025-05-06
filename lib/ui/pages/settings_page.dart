// lib/features/settings/view/settings_page.dart

import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.playlist_add),
          title: const Text('Import Templates'),
          onTap: () {
            // TODO: open your template-import flow
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Notifications'),
          onTap: () {
            // TODO: navigate to notification settings
          },
        ),
        ListTile(
          leading: const Icon(Icons.palette),
          title: const Text('Theme'),
          onTap: () {
            // TODO: toggle dark/light mode
          },
        ),
        // add more settings here...
      ],
    );
  }
}
