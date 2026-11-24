import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/prayer_item.dart';
import '../../services/prayer_provider.dart';
import '../theme/app_theme.dart';

/// Opens a modal bottom sheet allowing the user to pick a Sunnah preset
/// (Mu'akkadah / Mu'akkadah + Mustahabbah) or customize each prayer's
/// Sunnah & Witr rak‘ah counts according to their madhhab.
Future<void> showPrayerSunnahSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const _PrayerSunnahSheet(),
  );
}

class _PrayerSunnahSheet extends ConsumerStatefulWidget {
  const _PrayerSunnahSheet();

  @override
  ConsumerState<_PrayerSunnahSheet> createState() => _PrayerSunnahSheetState();
}

class _PrayerSunnahSheetState extends ConsumerState<_PrayerSunnahSheet> {
  late List<PrayerSunnahConfig> _draft;

  static const _sunnahOptions = [0, 2, 4];
  static const _witrOptions = [0, 1, 3, 5];

  @override
  void initState() {
    super.initState();
    _draft = List<PrayerSunnahConfig>.from(ref.read(prayerConfigProvider));
  }

  void _updateAt(
    int index,
    PrayerSunnahConfig Function(PrayerSunnahConfig c) transform,
  ) {
    setState(() {
      _draft = [
        for (int i = 0; i < _draft.length; i++)
          if (i == index) transform(_draft[i]) else _draft[i],
      ];
    });
  }

  Future<void> _save() async {
    await ref.read(prayerConfigProvider.notifier).saveConfig(_draft);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Column(
          children: [
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: [
                  Text(
                    'Customize Sunnah Prayers',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose Mu’akkadah (default) or include Mustahabbah rak‘ahs according to your madhhab.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () => setState(() {
                          _draft = List<PrayerSunnahConfig>.from(
                            PrayerSunnahConfig.muakkadahDefaults,
                          );
                        }),
                        child: const Text('Mu’akkadah (Default)'),
                      ),
                      OutlinedButton(
                        onPressed: () => setState(() {
                          _draft = List<PrayerSunnahConfig>.from(
                            PrayerSunnahConfig.muakkadahAndMustahabbah,
                          );
                        }),
                        child: const Text('Mu’akkadah + Mustahabbah'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (int i = 0; i < _draft.length; i++) ...[
                    _PrayerConfigCard(
                      config: _draft[i],
                      sunnahOptions: _sunnahOptions,
                      witrOptions: _witrOptions,
                      onBeforeSunnahChanged: (v) =>
                          _updateAt(i, (c) => c.copyWith(beforeSunnah: v)),
                      onAfterSunnahChanged: (v) =>
                          _updateAt(i, (c) => c.copyWith(sunnah: v)),
                      onWitrChanged: (v) =>
                          _updateAt(i, (c) => c.copyWith(witr: v)),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('Save Sunnah Settings'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PrayerConfigCard extends StatelessWidget {
  final PrayerSunnahConfig config;
  final List<int> sunnahOptions;
  final List<int> witrOptions;
  final ValueChanged<int> onBeforeSunnahChanged;
  final ValueChanged<int> onAfterSunnahChanged;
  final ValueChanged<int> onWitrChanged;

  const _PrayerConfigCard({
    required this.config,
    required this.sunnahOptions,
    required this.witrOptions,
    required this.onBeforeSunnahChanged,
    required this.onAfterSunnahChanged,
    required this.onWitrChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    final theme = Theme.of(context);
    final isIsha = config.name == 'Isha';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  config.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Fard (${config.fard})',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.mutedText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _RakahOptionRow(
              label: 'Before Fard',
              options: sunnahOptions,
              selected: config.beforeSunnah,
              onChanged: onBeforeSunnahChanged,
            ),
            if (config.name != 'Fajr' && config.name != 'Asr') ...[
              const SizedBox(height: 8),
              _RakahOptionRow(
                label: 'After Fard',
                options: sunnahOptions,
                selected: config.sunnah,
                onChanged: onAfterSunnahChanged,
              ),
            ],
            if (isIsha) ...[
              const SizedBox(height: 8),
              _RakahOptionRow(
                label: 'Witr',
                options: witrOptions,
                selected: config.witr,
                onChanged: onWitrChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RakahOptionRow extends StatelessWidget {
  final String label;
  final List<int> options;
  final int selected;
  final ValueChanged<int> onChanged;

  const _RakahOptionRow({
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.mutedText,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 6,
            children: options.map((val) {
              final isSelected = val == selected;
              return ChoiceChip(
                label: Text(val == 0 ? 'None' : '$val'),
                selected: isSelected,
                showCheckmark: false,
                selectedColor: colors.emerald,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : null,
                ),
                onSelected: (_) => onChanged(val),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
