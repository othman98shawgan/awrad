import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/awrad_status.dart';
import '../../models/awrad_task.dart';
import '../../services/awrad_provider.dart';
import '../../services/date_utils.dart';
import '../../services/progress_provider.dart';
import '../../services/selected_date_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/awrad_task_card.dart';
import '../widgets/awrad_task_sheet.dart';
import '../widgets/date_switcher_bar.dart';
import '../widgets/template_import_sheet.dart';

enum _TaskFilter { all, pending, done }

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  static const int initialPage = 10000;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late PageController _controller;
  _TaskFilter _filter = _TaskFilter.all;

  @override
  void initState() {
    super.initState();
    final today = normalizeDate(DateTime.now());
    final selected = ref.read(selectedDateProvider);
    final offset = selected.difference(today).inDays;
    _controller = PageController(initialPage: HomePage.initialPage + offset);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = normalizeDate(DateTime.now());

    ref.listen<DateTime>(selectedDateProvider, (_, next) {
      final offset = normalizeDate(next).difference(today).inDays;
      final targetPage = HomePage.initialPage + offset;

      if (_controller.hasClients && _controller.page?.round() != targetPage) {
        _controller.jumpToPage(targetPage);
      }
    });

    return Column(
      children: [
        DateSwitcherBar(
          onPrevious: () {
            _controller.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            );
          },
          onNext: () {
            _controller.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            );
          },
        ),
        Expanded(
          child: PageView.builder(
            controller: _controller,
            allowImplicitScrolling: true,
            onPageChanged: (pageIndex) {
              final offset = pageIndex - HomePage.initialPage;
              final newDate =
                  DateTime(today.year, today.month, today.day + offset);
              ref.read(selectedDateProvider.notifier).selectDate(newDate);
            },
            itemBuilder: (context, pageIndex) {
              final offset = pageIndex - HomePage.initialPage;
              final pageDate =
                  DateTime(today.year, today.month, today.day + offset);
              return RepaintBoundary(
                child: _DailyAwradPage(
                  pageDate: pageDate,
                  filter: _filter,
                  onFilterChanged: (f) => setState(() => _filter = f),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DailyAwradPage extends ConsumerWidget {
  final DateTime pageDate;
  final _TaskFilter filter;
  final ValueChanged<_TaskFilter> onFilterChanged;

  const _DailyAwradPage({
    required this.pageDate,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.awradColors;
    final allTasks = ref.watch(awradTasksProvider);
    final tasks = allTasks.where((t) => t.appliesTo(pageDate)).toList();
    final log = ref.watch(dailyAwradLogProvider(pageDate));
    final logNotifier = ref.read(dailyAwradLogProvider(pageDate).notifier);

    final doneCount =
        tasks.where((t) => log.statusFor(t.id) == AwradStatus.done).length;
    final halfCount =
        tasks.where((t) => log.statusFor(t.id) == AwradStatus.halfDone).length;
    final pendingCount = tasks.length - doneCount;

    final visibleTasks = switch (filter) {
      _TaskFilter.all => tasks,
      _TaskFilter.pending =>
        tasks.where((t) => log.statusFor(t.id) != AwradStatus.done).toList(),
      _TaskFilter.done =>
        tasks.where((t) => log.statusFor(t.id) == AwradStatus.done).toList(),
    };

    final canReorder = filter == _TaskFilter.all && visibleTasks.length > 1;

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          sliver: SliverToBoxAdapter(
            child: _DailyProgressCard(
              pageDate: pageDate,
              totalCount: tasks.length,
              doneCount: doneCount,
              halfCount: halfCount,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterPill(
                          label: 'All (${tasks.length})',
                          selected: filter == _TaskFilter.all,
                          onTap: () => onFilterChanged(_TaskFilter.all),
                        ),
                        const SizedBox(width: 8),
                        _FilterPill(
                          label: 'Pending ($pendingCount)',
                          selected: filter == _TaskFilter.pending,
                          onTap: () => onFilterChanged(_TaskFilter.pending),
                        ),
                        const SizedBox(width: 8),
                        _FilterPill(
                          label: 'Done ($doneCount)',
                          selected: filter == _TaskFilter.done,
                          onTap: () => onFilterChanged(_TaskFilter.done),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (tasks.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.checklist_rounded,
                    size: 44,
                    color: colors.mutedText,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    allTasks.isEmpty
                        ? 'Your Awrad list is empty'
                        : 'No Awrad scheduled for this day',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (allTasks.isEmpty) ...[
                    TextButton(
                      onPressed: () => showTemplateImportSheet(context),
                      child: Text(
                        'Tap here to choose from templates',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.emerald,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: colors.emerald,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => showAwradTaskSheet(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('New Wird'),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: () => showAwradTaskSheet(context),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('New Wird'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => showTemplateImportSheet(context),
                          icon: const Icon(Icons.playlist_add, size: 18),
                          label: const Text('Import Templates'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          )
        else if (visibleTasks.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                filter == _TaskFilter.pending
                    ? 'All Awrad completed for this day!'
                    : 'No completed Awrad yet.',
                style: TextStyle(color: colors.mutedText),
              ),
            ),
          )
        else if (canReorder)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverReorderableList(
              itemCount: visibleTasks.length,
              onReorderItem: (oldVisible, newVisible) {
                _reorderVisibleTasks(
                  ref,
                  allTasks,
                  visibleTasks,
                  oldVisible,
                  newVisible,
                );
              },
              itemBuilder: (context, idx) {
                final task = visibleTasks[idx];
                final status = log.statusFor(task.id);
                final dailyNote = log.noteFor(task.id);
                return Padding(
                  key: ValueKey(task.id),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AwradTaskCard(
                    task: task,
                    status: status,
                    dailyNote: dailyNote,
                    reorderIndex: idx,
                    onToggleStatus: () => logNotifier.cycleTaskStatus(task.id),
                    onLongPress: () => showAwradTaskSheet(
                      context,
                      task: task,
                      forDate: pageDate,
                      dailyNote: dailyNote,
                    ),
                  ),
                );
              },
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.separated(
              itemCount: visibleTasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final task = visibleTasks[idx];
                final status = log.statusFor(task.id);
                final dailyNote = log.noteFor(task.id);
                return AwradTaskCard(
                  key: ValueKey(task.id),
                  task: task,
                  status: status,
                  dailyNote: dailyNote,
                  onToggleStatus: () => logNotifier.cycleTaskStatus(task.id),
                  onLongPress: () => showAwradTaskSheet(
                    context,
                    task: task,
                    forDate: pageDate,
                    dailyNote: dailyNote,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _reorderVisibleTasks(
    WidgetRef ref,
    List<AwradTask> allTasks,
    List<AwradTask> visibleTasks,
    int oldVisibleIndex,
    int targetVisible,
  ) {
    if (targetVisible < 0 || targetVisible >= visibleTasks.length) return;

    final movedTask = visibleTasks[oldVisibleIndex];
    final targetTask = visibleTasks[targetVisible];
    final oldMaster = allTasks.indexWhere((t) => t.id == movedTask.id);
    final targetMaster = allTasks.indexWhere((t) => t.id == targetTask.id);
    if (oldMaster == -1 || targetMaster == -1) return;

    final adjustedNewMaster =
        targetMaster > oldMaster ? targetMaster + 1 : targetMaster;
    ref
        .read(awradTasksProvider.notifier)
        .reorderTasks(oldMaster, adjustedNewMaster);
  }
}

class _DailyProgressCard extends ConsumerWidget {
  final DateTime pageDate;
  final int totalCount;
  final int doneCount;
  final int halfCount;

  const _DailyProgressCard({
    required this.pageDate,
    required this.totalCount,
    required this.doneCount,
    required this.halfCount,
  });

  static const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.awradColors;
    final theme = Theme.of(context);

    final score =
        totalCount == 0 ? 0.0 : (doneCount + (halfCount * 0.5)) / totalCount;
    final percent = (score * 100).round();
    final doneFrac = totalCount == 0 ? 0.0 : doneCount / totalCount;
    final halfFrac = totalCount == 0 ? 0.0 : halfCount / totalCount;

    final start = DateTime(pageDate.year, pageDate.month, pageDate.day - 6);
    final weekAsync = ref.watch(
      awradScoresRangeProvider(ProgressRangeQuery(start, pageDate)),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Progress',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.emeraldSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$percent%',
                    style: TextStyle(
                      color: colors.emerald,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              halfCount > 0
                  ? '$doneCount of $totalCount done · $halfCount half done'
                  : '$doneCount of $totalCount done',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.mutedText,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    if (doneFrac > 0)
                      Expanded(
                        flex: (doneFrac * 1000).round(),
                        child: Container(color: colors.emerald),
                      ),
                    if (halfFrac > 0)
                      Expanded(
                        flex: (halfFrac * 1000).round(),
                        child: Container(color: colors.amber),
                      ),
                    if ((1 - doneFrac - halfFrac) > 0.001)
                      Expanded(
                        flex: ((1 - doneFrac - halfFrac) * 1000).round(),
                        child: Container(color: colors.heatmapLevels[0]),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _buildWeekStrip(
              context,
              ref,
              colors,
              theme,
              weekAsync.valueOrNull,
              score,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekStrip(
    BuildContext context,
    WidgetRef ref,
    AwradColors colors,
    ThemeData theme,
    Map<DateTime, double>? scoresByDate,
    double currentDayScore,
  ) {
    final start = DateTime(pageDate.year, pageDate.month, pageDate.day - 6);
    final dates = datesInRange(start, pageDate);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: dates.map((date) {
        final isSelected = date == pageDate;
        final dayScore =
            isSelected ? currentDayScore : (scoresByDate?[date] ?? 0.0);
        final cellColor = _colorForScore(dayScore, colors);

        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () =>
              ref.read(selectedDateProvider.notifier).selectDate(date),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Column(
              children: [
                Text(
                  _dayLetters[date.weekday - 1],
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? colors.emerald : colors.mutedText,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: BorderRadius.circular(7),
                    border: isSelected
                        ? Border.all(color: colors.emerald, width: 2)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _colorForScore(double score, AwradColors colors) {
    if (score <= 0) return colors.heatmapLevels[0];
    if (score < 0.4) return colors.heatmapLevels[1];
    if (score < 0.75) return colors.heatmapLevels[2];
    return colors.heatmapLevels[3];
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: colors.emerald,
      backgroundColor: Theme.of(context).colorScheme.surface,
      side: BorderSide(
        color: selected ? colors.emerald : colors.cardBorder,
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: selected ? Colors.white : colors.mutedText,
      ),
      onSelected: (_) => onTap(),
    );
  }
}
