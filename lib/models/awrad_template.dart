import 'awrad_task.dart';

/// A single item inside a curated [AwradTemplate].
class AwradTemplateTask {
  final String title;
  final AwradCategory category;
  final Set<int> repeatWeekdays;
  final String? note;

  const AwradTemplateTask({
    required this.title,
    this.category = AwradCategory.other,
    this.repeatWeekdays = const {},
    this.note,
  });
}

/// A curated, importable collection of Awrad tasks.
class AwradTemplate {
  final String id;
  final String name;
  final String description;
  final List<AwradTemplateTask> tasks;

  const AwradTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.tasks,
  });
}
