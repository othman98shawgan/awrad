/// Tri-state completion status for an Awrad task or Prayer.
enum AwradStatus {
  notDone,
  halfDone,
  done;

  /// Numeric weight used for daily/weekly/monthly progress calculations.
  double get score => switch (this) {
        AwradStatus.notDone => 0.0,
        AwradStatus.halfDone => 0.5,
        AwradStatus.done => 1.0,
      };

  /// Maps to Flutter's tri-state [Checkbox] value (`false`, `null`, `true`).
  bool? toTristate() => switch (this) {
        AwradStatus.notDone => false,
        AwradStatus.halfDone => null,
        AwradStatus.done => true,
      };

  /// Cycles through states on tap: notDone -> done -> halfDone -> notDone.
  AwradStatus next() => switch (this) {
        AwradStatus.notDone => AwradStatus.done,
        AwradStatus.done => AwradStatus.halfDone,
        AwradStatus.halfDone => AwradStatus.notDone,
      };

  static AwradStatus fromTristate(bool? value) {
    if (value == true) return AwradStatus.done;
    if (value == null) return AwradStatus.halfDone;
    return AwradStatus.notDone;
  }

  static AwradStatus fromJson(String? value) {
    return AwradStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AwradStatus.notDone,
    );
  }
}
