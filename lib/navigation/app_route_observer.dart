import 'package:flutter/widgets.dart';

/// Tells screens when another full screen opens over them or closes. The home
/// screen uses it to know whether For You is really on screen.
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
