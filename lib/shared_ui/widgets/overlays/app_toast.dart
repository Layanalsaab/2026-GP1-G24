import 'dart:async';

import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text.dart';

/// The small bottom pop-up, used only for failures such as no internet (the
/// green success toast of the prototype `.toast`, docs/02 §8.15): bottom 84, 16 px
/// side margins, green, radius 14, gold circle check, 14/20 white text. Stays
/// 2.4 s, enters with a fade + 16 px rise (300 ms), leaves with a 200 ms fade.
/// A new toast replaces the current one and restarts the timer.
///
/// `AppToast.error(context, message)` from widgets, or
/// `AppToast.errorGlobal(message)` from a view model after assigning
/// [navigatorKey] to the app's `MaterialApp.navigatorKey`. [show] and
/// [showGlobal] are switched off (confirmations show no pop-up).
class AppToast {
  AppToast._();

  /// Give this to `MaterialApp(navigatorKey: AppToast.navigatorKey)` so toasts
  /// can be shown without a BuildContext.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const Duration visible = Duration(milliseconds: 2400);

  static OverlayEntry? _entry;
  static GlobalKey<_ToastViewState>? _viewKey;
  static Timer? _timer;

  /// Shows [message] using the overlay of [context].
  static void show(BuildContext context, String message) {
    // Switched off: confirmations and field mistakes show no pop-up. Only
    // [error] (network / server failures) does.
  }

  /// Shows [message] through [navigatorKey] (no BuildContext needed).
  static void showGlobal(String message) {
    // Switched off, see [show].
  }

  /// Shows [message] as a small pop-up at the bottom, but ONLY for a real
  /// failure (no internet, server or device error). Use this for those.
  static void error(BuildContext context, String message) {
    _present(Overlay.maybeOf(context, rootOverlay: true), message);
  }

  /// [error] without a BuildContext.
  static void errorGlobal(String message) {
    _present(navigatorKey.currentState?.overlay, message);
  }

  static void _present(OverlayState? overlay, String message) {
    if (overlay == null || message.isEmpty) return;
    _removeNow();
    final key = GlobalKey<_ToastViewState>();
    final entry = OverlayEntry(
      builder: (_) => _ToastView(key: key, message: message),
    );
    _viewKey = key;
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(visible, _dismiss);
  }

  static void _dismiss() {
    final state = _viewKey?.currentState;
    final entry = _entry;
    if (state == null || entry == null) {
      _removeNow();
      return;
    }
    state.exit(() {
      if (identical(_entry, entry)) {
        entry.remove();
        _entry = null;
        _viewKey = null;
      } else {
        entry.remove();
      }
    });
  }

  static void _removeNow() {
    _timer?.cancel();
    _timer = null;
    final e = _entry;
    _entry = null;
    _viewKey = null;
    if (e != null) {
      try {
        e.remove();
      } catch (_) {}
    }
  }
}

class _ToastView extends StatefulWidget {
  const _ToastView({super.key, required this.message});

  final String message;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    reverseDuration: const Duration(milliseconds: 200),
  );
  late final Animation<double> a = CurvedAnimation(
    parent: _c,
    curve: Curves.ease,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.reduced(context)) {
      _c.duration = Motion.reducedFade;
      _c.reverseDuration = Motion.reducedFade;
    }
    _c.forward();
  }

  void exit(VoidCallback done) {
    if (!mounted) {
      done();
      return;
    }
    _c.reverse().whenComplete(done);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    final bottom = 84 + MediaQuery.viewPaddingOf(context).bottom;
    return Positioned(
      left: 16,
      right: 16,
      bottom: bottom,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: a,
          builder: (context, child) => Opacity(
            opacity: a.value,
            child: reduced
                ? child
                : Transform.translate(
                    offset: Offset(0, 16 * (1 - a.value)),
                    child: child,
                  ),
          ),
          child: Semantics(
            liveRegion: true,
            label: widget.message,
            excludeSemantics: true,
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppShadow.toast,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const AppIcon.filled(
                        AppIcons.check,
                        size: 14,
                        color: AppColors.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(widget.message, style: AppText.toast)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
