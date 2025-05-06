import 'package:flutter/widgets.dart';

class SlowPagePhysics extends PageScrollPhysics {
  const SlowPagePhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  SlowPagePhysics applyTo(ScrollPhysics? ancestor) {
    return SlowPagePhysics(parent: buildParent(ancestor));
  }

  @override
  double get minFlingVelocity => 1000.0; // Higher = requires a stronger swipe to move pages
}
