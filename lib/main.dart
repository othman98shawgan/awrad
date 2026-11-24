import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'ui/pages/home_page.dart';
import 'ui/pages/prayer_progress_page.dart';
import 'ui/pages/progress_page.dart';
import 'ui/pages/settings_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  WakelockPlus.enable(); // Keep app awake

  runApp(const ProviderScope(child: OradApp()));
}

class OradApp extends StatefulWidget {
  const OradApp({super.key});

  @override
  State<OradApp> createState() => _OradAppState();
}

class _OradAppState extends State<OradApp> {
  int _currentIndex = 0;

  static const _pages = [
    HomePage(),
    PrayerProgressPage(),
    ProgressPage(),
    SettingsPage(),
  ];

  static const _titles = [
    'Awrad',
    'Prayer',
    'Progress',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text(_titles[_currentIndex]),
          centerTitle: true,
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Awrad'),
            BottomNavigationBarItem(icon: Icon(Icons.mosque), label: 'Prayer'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Progress'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
