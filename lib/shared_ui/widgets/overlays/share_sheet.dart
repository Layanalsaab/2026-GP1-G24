import 'package:flutter/material.dart';

import '../../../app_constants/profile_strings.dart';
import '../../icons/app_icons.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import 'app_bottom_sheet.dart';
import 'app_toast.dart';

/// Where a share option goes. The sheet only builds the web address / mail
/// link; opening it (and the phone's own share sheet) is done by the caller, so
/// the sheet can be tested without a phone.
typedef ShareLauncher = Future<bool> Function(Uri uri);
typedef SystemShare = Future<void> Function(String text, String subject);

/// The share sheet every share icon opens: a row of the common apps
/// (WhatsApp, X, Telegram, LinkedIn, Facebook, Email), "Copy link" and "More",
/// which opens the phone's own share sheet with every app installed.
///
/// [url] is the link of the item, [title] its name (used in the message:
/// "Rafeeq Health on Start.sa"). [copy] copies the link; [launch] opens an
/// app or web address; [systemShare] opens the phone's share sheet.
Future<void> showShareSheet(
  BuildContext context, {
  required String url,
  String? title,
  required VoidCallback copy,
  required ShareLauncher launch,
  required SystemShare systemShare,
}) {
  return showAppBottomSheet<void>(
    context,
    builder: (sheet) => AppSheetScaffold(
      title: ProfileStrings.shareTitle,
      child: _ShareOptions(
        url: url,
        title: title,
        copy: copy,
        launch: launch,
        systemShare: systemShare,
      ),
    ),
  );
}

class _ShareOption {
  const _ShareOption({
    required this.label,
    required this.fill,
    required this.onTap,
    this.icon,
    this.glyph,
  });

  final String label;
  final Color fill;

  /// An [AppIcons] path, or a short [glyph] text ("X", "f").
  final String? icon;
  final String? glyph;
  final Future<void> Function() onTap;
}

class _ShareOptions extends StatelessWidget {
  const _ShareOptions({
    required this.url,
    required this.title,
    required this.copy,
    required this.launch,
    required this.systemShare,
  });

  final String url;
  final String? title;
  final VoidCallback copy;
  final ShareLauncher launch;
  final SystemShare systemShare;

  /// "Rafeeq Health on Start.sa", or a plain line when the name is unknown.
  String get _message {
    final name = (title ?? '').trim();
    return name.isEmpty
        ? ProfileStrings.shareMessagePlain
        : ProfileStrings.shareMessage(name);
  }

  /// [base] with [query] percent-encoded ("%20" for a space: Uri's own
  /// queryParameters would write "+", which some apps show as a plus sign).
  Uri _web(String base, Map<String, String> query) => Uri.parse(
    '$base${base.contains('?') ? '&' : '?'}'
    '${query.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}',
  );

  @override
  Widget build(BuildContext context) {
    Future<void> open(Uri uri) async {
      var ok = false;
      try {
        ok = await launch(uri);
      } catch (_) {
        ok = false;
      }
      if (!ok && context.mounted) {
        AppToast.error(context, ProfileStrings.shareCantOpen);
      }
    }

    final text = '$_message\n$url';
    final options = <_ShareOption>[
      _ShareOption(
        label: ProfileStrings.copyLink,
        fill: AppColors.moss600,
        icon: AppIcons.link,
        onTap: () async => copy(),
      ),
      _ShareOption(
        label: 'WhatsApp',
        fill: const Color(0xFF25D366),
        icon: AppIcons.chat,
        onTap: () => open(_web('https://wa.me/', {'text': text})),
      ),
      _ShareOption(
        label: 'X',
        fill: const Color(0xFF111111),
        glyph: 'X',
        onTap: () => open(
          _web('https://twitter.com/intent/tweet', {
            'text': _message,
            'url': url,
          }),
        ),
      ),
      _ShareOption(
        label: 'Telegram',
        fill: const Color(0xFF229ED9),
        icon: AppIcons.send,
        onTap: () => open(
          _web('https://t.me/share/url', {'url': url, 'text': _message}),
        ),
      ),
      _ShareOption(
        label: 'LinkedIn',
        fill: const Color(0xFF0A66C2),
        icon: AppIcons.linkedIn,
        onTap: () => open(
          _web('https://www.linkedin.com/sharing/share-offsite/', {'url': url}),
        ),
      ),
      _ShareOption(
        label: 'Facebook',
        fill: const Color(0xFF1877F2),
        glyph: 'f',
        onTap: () => open(
          _web('https://www.facebook.com/sharer/sharer.php', {'u': url}),
        ),
      ),
      _ShareOption(
        label: ProfileStrings.shareEmail,
        fill: const Color(0xFF6B7280),
        icon: AppIcons.mail,
        onTap: () => open(
          Uri(
            scheme: 'mailto',
            // Uri(queryParameters) would turn spaces into "+", which a mail
            // app shows as plus signs.
            query:
                'subject=${Uri.encodeComponent(_message)}'
                '&body=${Uri.encodeComponent(text)}',
          ),
        ),
      ),
      _ShareOption(
        label: ProfileStrings.shareMore,
        fill: AppColors.gold700,
        icon: AppIcons.share,
        onTap: () async {
          try {
            await systemShare(text, _message);
          } catch (_) {
            if (context.mounted) {
              AppToast.error(context, ProfileStrings.shareCantOpen);
            }
          }
        },
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      child: LayoutBuilder(
        builder: (context, box) {
          // Four to a row, each a quarter of the width.
          final w = (box.maxWidth / 4).floorToDouble();
          return Wrap(
            alignment: WrapAlignment.start,
            runSpacing: 14,
            children: [
              for (final o in options)
                SizedBox(
                  width: w,
                  child: _Tile(
                    option: o,
                    onTap: () async {
                      // The sheet closes first, then the app opens.
                      Navigator.of(context).pop();
                      await o.onTap();
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.option, required this.onTap});

  final _ShareOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final o = option;
    return Semantics(
      button: true,
      label: o.label,
      excludeSemantics: true,
      child: Pressable(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: o.fill,
                  shape: BoxShape.circle,
                ),
                child: o.icon != null
                    ? AppIcon.filled(o.icon!, size: 26, color: Colors.white)
                    : Text(
                        o.glyph ?? '',
                        style: AppText.sans(
                          size: 24,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: 6),
              Text(
                o.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppText.sans(size: 12.5, color: AppColors.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
