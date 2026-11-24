/// Categories for organizing daily Awrad tasks.
enum AwradCategory {
  quran('Quran'),
  prayer('Prayer'),
  adhkar('Adhkar'),
  sunnah('Sunnah'),
  knowledge('Knowledge'),
  fasting('Fasting'),
  other('General');

  final String label;
  const AwradCategory(this.label);

  static AwradCategory fromJson(String? value) {
    return AwradCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AwradCategory.other,
    );
  }
}

/// Definition of a recurring or daily Awrad task (independent of daily logs).
class AwradTask {
  final String id;
  final String title;
  final AwradCategory category;

  /// ISO weekdays (`DateTime.monday` = 1 .. `DateTime.sunday` = 7).
  /// An empty set means the task repeats every day.
  final Set<int> repeatWeekdays;
  final int sortOrder;
  final String? note;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AwradTask({
    required this.id,
    required this.title,
    this.category = AwradCategory.other,
    this.repeatWeekdays = const {},
    this.sortOrder = 0,
    this.note,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Whether this task should appear on [date].
  bool appliesTo(DateTime date) {
    if (isArchived) return false;
    if (repeatWeekdays.isEmpty) return true;
    return repeatWeekdays.contains(date.weekday);
  }

  AwradTask copyWith({
    String? id,
    String? title,
    AwradCategory? category,
    Set<int>? repeatWeekdays,
    int? sortOrder,
    String? note,
    bool clearNote = false,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AwradTask(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      repeatWeekdays: repeatWeekdays ?? this.repeatWeekdays,
      sortOrder: sortOrder ?? this.sortOrder,
      note: clearNote ? null : (note ?? this.note),
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'category': category.name,
        'repeatWeekdays': repeatWeekdays.toList()..sort(),
        'sortOrder': sortOrder,
        'note': note,
        'isArchived': isArchived,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory AwradTask.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    final rawDays = map['repeatWeekdays'];
    final weekdays = rawDays is List
        ? rawDays.map((e) => (e as num).toInt()).where((d) => d >= 1 && d <= 7).toSet()
        : <int>{};

    return AwradTask(
      id: map['id'] as String,
      title: map['title'] as String,
      category: AwradCategory.fromJson(map['category'] as String?),
      repeatWeekdays: weekdays,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      note: map['note'] as String?,
      isArchived: (map['isArchived'] as bool?) ?? false,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? now,
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? now,
    );
  }
}
