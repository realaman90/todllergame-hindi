import 'package:flutter/widgets.dart';

/// Global UI scale for larger canvases (founder report 2026-07-22:
/// tiles looked small on iPad). Phones stay 1.0; tablets grow up to
/// 1.35× — applied inside the shared widgets (ArtTile, MithuTalking,
/// DoorwayCard, scene objects), so games inherit it for free.
double uiScale(BuildContext context) =>
    (MediaQuery.sizeOf(context).shortestSide / 600).clamp(1.0, 1.35);
