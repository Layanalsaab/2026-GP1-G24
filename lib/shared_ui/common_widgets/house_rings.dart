import 'package:flutter/widgets.dart';

import 'svg_asset.dart';

/// The decorative house-shaped rings and gold sparkles used behind the splash
/// and welcome screens. [dy] shifts the rings vertically (Figma coordinates).
List<Widget> houseRings({double dy = 0, required List<Offset> sparkles}) => [
      positionedSvg('house_ring0.svg', left: 50, top: 79 + dy, width: 260, height: 325),
      positionedSvg('house_ring1.svg', left: -5, top: 48.5 + dy, width: 370, height: 462.5),
      positionedSvg('house_ring2.svg', left: -60, top: 18 + dy, width: 480, height: 600),
      positionedSvg('house_ring3.svg', left: -115, top: -12.5 + dy, width: 590, height: 737.5),
      for (final p in sparkles)
        positionedSvg('sparkle.svg', left: p.dx, top: p.dy, width: 6, height: 6),
    ];
