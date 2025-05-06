import 'package:flutter/widgets.dart';

class ExtraSmoothPagePhysics extends PageScrollPhysics {
  const ExtraSmoothPagePhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  ExtraSmoothPagePhysics applyTo(ScrollPhysics? ancestor) {
    return ExtraSmoothPagePhysics(parent: buildParent(ancestor));
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    final simulation = super.createBallisticSimulation(position, velocity);
    if (simulation == null) return null;
    return ClampingScrollSimulation(
      position: position.pixels,
      velocity: velocity,
      friction: 0.015, // Lower friction = slower stop
      tolerance: tolerance,
    );
  }
}
