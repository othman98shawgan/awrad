import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A single source-of-truth for the currently selected date.
final selectedDateProvider = StateProvider<DateTime>((_) => DateTime.now());
